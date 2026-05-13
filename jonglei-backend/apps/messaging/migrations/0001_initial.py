import uuid
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('marketplace', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Thread',
            fields=[
                ('id',         models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('listing', models.ForeignKey(
                    blank=True, null=True,
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='threads', to='marketplace.fishlisting',
                )),
                ('buyer', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='buyer_threads', to=settings.AUTH_USER_MODEL,
                )),
                ('seller', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='seller_threads', to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'db_table': 'message_threads',
                'ordering': ['-updated_at'],
                'unique_together': {('listing', 'buyer')},
            },
        ),
        migrations.AddIndex(
            model_name='thread',
            index=models.Index(fields=['buyer'],  name='msg_thread_buyer_idx'),
        ),
        migrations.AddIndex(
            model_name='thread',
            index=models.Index(fields=['seller'], name='msg_thread_seller_idx'),
        ),
        migrations.CreateModel(
            name='Message',
            fields=[
                ('id',         models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('body',       models.TextField()),
                ('is_read',    models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('thread', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='messages', to='messaging.thread',
                )),
                ('sender', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='sent_messages', to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={
                'db_table': 'messages',
                'ordering': ['created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='message',
            index=models.Index(fields=['thread', 'is_read'], name='msg_thread_read_idx'),
        ),
    ]
