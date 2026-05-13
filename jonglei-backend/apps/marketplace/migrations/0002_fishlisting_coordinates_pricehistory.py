from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('marketplace', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='fishlisting',
            name='latitude',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='fishlisting',
            name='longitude',
            field=models.FloatField(blank=True, null=True),
        ),

        migrations.CreateModel(
            name='PriceHistory',
            fields=[
                ('id',          models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('species',     models.CharField(db_index=True, max_length=100)),
                ('location',    models.CharField(db_index=True, max_length=200)),
                ('price_ssp',   models.DecimalField(decimal_places=2, max_digits=12)),
                ('source',      models.CharField(default='market', max_length=50,
                                                 help_text='market|reported|system')),
                ('recorded_at', models.DateTimeField(db_index=True)),
            ],
            options={
                'db_table': 'price_history',
                'ordering': ['-recorded_at'],
            },
        ),
        migrations.AddIndex(
            model_name='pricehistory',
            index=models.Index(fields=['species', 'recorded_at'], name='ph_species_time_idx'),
        ),
        migrations.AddIndex(
            model_name='pricehistory',
            index=models.Index(fields=['location', 'recorded_at'], name='ph_location_time_idx'),
        ),
    ]
