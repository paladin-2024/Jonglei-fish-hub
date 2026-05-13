"""
Management command: python manage.py seed_data

Creates demo users + listings + orders + shipments for lecture demos.
Safe to run multiple times (skips existing phone numbers).
"""
import random
from decimal import Decimal
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.accounts.models import User
from apps.marketplace.models import FishListing, Order
from apps.transport.models import Shipment, TransportJob
from apps.clearance.models import BorderClearance


LOCATIONS = ['Bor', 'Juba', 'Malakal', 'Wau', 'Fangak', 'Renk']
SPECIES   = ['Nile Perch', 'Tilapia', 'Catfish', 'Lungfish', 'Smoked Nile Perch']

DEMO_USERS = [
    # (phone, password, role, username)
    ('+256700000001', 'demo1234', 'TRADER',          'trader_john'),
    ('+256700000002', 'demo1234', 'TRADER',          'trader_mary'),
    ('+256700000003', 'demo1234', 'BUYER',           'buyer_peter'),
    ('+256700000004', 'demo1234', 'BUYER',           'buyer_grace'),
    ('+256700000005', 'demo1234', 'TRANSPORTER',     'driver_samuel'),
    ('+256700000006', 'demo1234', 'TRANSPORTER',     'driver_esther'),
    ('+256700000007', 'demo1234', 'BORDER_OFFICIAL', 'officer_james'),
    ('+256700000008', 'demo1234', 'MARKET_OFFICIAL', 'official_sarah'),
]


class Command(BaseCommand):
    help = 'Seed database with demo data for lectures'

    def handle(self, *args, **options):
        self.stdout.write('Seeding demo data…')

        # Create users
        users_by_role = {'TRADER': [], 'BUYER': [], 'TRANSPORTER': [], 'BORDER_OFFICIAL': [], 'MARKET_OFFICIAL': []}
        for phone, pw, role, username in DEMO_USERS:
            user, created = User.objects.get_or_create(
                phone_number=phone,
                defaults={
                    'username': username,
                    'role': role,
                    'is_verified': True,
                    'location': random.choice(LOCATIONS),
                }
            )
            if created:
                user.set_password(pw)
                user.save(update_fields=['password'])
                self.stdout.write(f'  Created {role}: {username} ({phone})')
            users_by_role[role].append(user)

        traders = users_by_role['TRADER']
        buyers  = users_by_role['BUYER']
        transporters = users_by_role['TRANSPORTER']
        officers = users_by_role['BORDER_OFFICIAL']

        # Create listings
        listing_data = [
            ('Nile Perch',          'Bor',     500, 2450, 'ACTIVE'),
            ('Tilapia',             'Bor',     300, 1800, 'ACTIVE'),
            ('Catfish',             'Malakal', 200, 1200, 'ACTIVE'),
            ('Lungfish',            'Wau',     150, 1600, 'ACTIVE'),
            ('Smoked Nile Perch',   'Juba',    400, 3200, 'ACTIVE'),
            ('Tilapia',             'Fangak',  250, 1750, 'DRAFT'),
            ('Nile Perch',          'Renk',    180, 2950, 'ACTIVE'),
            ('Catfish',             'Juba',    120, 1900, 'SOLD'),
            ('Lungfish',            'Malakal', 300, 1550, 'ACTIVE'),
            ('Nile Perch',          'Wau',     220, 2800, 'DRAFT'),
        ]
        listings = []
        for species, loc, qty, price, status in listing_data:
            seller = random.choice(traders)
            listing, _ = FishListing.objects.get_or_create(
                species=species,
                seller=seller,
                location=loc,
                defaults={
                    'quantity_kg': Decimal(qty),
                    'price_ssp':   Decimal(price),
                    'status':      status,
                    'description': f'Fresh {species} from {loc} market',
                }
            )
            listings.append(listing)
        self.stdout.write(f'  Listings: {len(listings)}')

        # Create orders against active listings
        active = [l for l in listings if l.status == 'ACTIVE']
        order_statuses = ['PENDING', 'CONFIRMED', 'IN_TRANSIT', 'CLEARED']
        orders = []
        for i, listing in enumerate(active[:6]):
            buyer = random.choice(buyers)
            qty   = Decimal(random.randint(50, min(int(listing.quantity_kg), 200)))
            total = qty * listing.price_ssp
            order, _ = Order.objects.get_or_create(
                listing=listing,
                buyer=buyer,
                defaults={
                    'quantity_kg': qty,
                    'total_price': total,
                    'status':      order_statuses[i % len(order_statuses)],
                }
            )
            orders.append(order)
        self.stdout.write(f'  Orders: {len(orders)}')

        # Create shipments for confirmed/in-transit/cleared orders
        shippable_statuses = ('CONFIRMED', 'IN_TRANSIT', 'CLEARED')
        shippable = [o for o in orders if o.status in shippable_statuses]
        shipment_statuses = {
            'CONFIRMED': 'CONFIRMED',
            'IN_TRANSIT': 'IN_TRANSIT',
            'CLEARED': 'CLEARED',
        }
        created_shipments = 0
        for order in shippable:
            if hasattr(order, 'shipment'):
                continue
            transporter = random.choice(transporters) if transporters else None
            ship = Shipment.objects.create(
                order=order,
                transporter=transporter,
                origin=order.listing.location,
                destination=random.choice([l for l in LOCATIONS if l != order.listing.location]),
                status=shipment_statuses.get(order.status, 'PENDING'),
                progress=Decimal('0.5') if order.status == 'IN_TRANSIT' else Decimal('0'),
                carrier_name='Jonglei Freight Co.',
            )
            TransportJob.objects.get_or_create(
                shipment=ship,
                defaults={
                    'pay_ssp':     Decimal(random.randint(5000, 20000)),
                    'transporter': transporter,
                    'status':      'ACTIVE' if order.status == 'IN_TRANSIT' else 'ACCEPTED',
                }
            )
            if order.status == 'CLEARED' and officers:
                BorderClearance.objects.get_or_create(
                    shipment=ship,
                    checkpoint='Bor Border Checkpoint',
                    defaults={
                        'officer': random.choice(officers),
                        'status':  'CLEARED',
                        'notes':   'All documents verified.',
                        'cleared_at': timezone.now(),
                    }
                )
            created_shipments += 1
        self.stdout.write(f'  Shipments: {created_shipments}')

        self.stdout.write(self.style.SUCCESS('Done! Demo credentials: +256700000001..8 / demo1234'))
