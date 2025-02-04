"""add servings column

Revision ID: add_servings_column_rev1
Revises: cafaa49323d4
Create Date: 2025-02-04 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_servings_column_rev1'
down_revision = 'cafaa49323d4'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add servings column
    op.add_column('recipes', sa.Column('servings', sa.Integer(), nullable=True))


def downgrade() -> None:
    # Remove servings column
    op.drop_column('recipes', 'servings')