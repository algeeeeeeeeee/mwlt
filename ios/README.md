# Meowlett Native (SwiftUI)

This directory is a separate native iOS implementation. The existing React/Vite PWA remains untouched.

## Current foundation

- Four-step onboarding ported from the latest web app: language, display name, monthly income, and appearance.
- Indonesian and English onboarding copy.
- Existing theme preset colors and custom primary/accent colors.
- Local transaction persistence in the app's Application Support directory.
- Starter Dashboard, Transactions, Reports, Date, and Settings tabs.
- Basic transaction creation and deletion.

## Important migration notes

The PWA stores data in browser localStorage and IndexedDB. A native app has a separate sandbox, so the native app cannot automatically see those browser records. A versioned backup import/export flow must be implemented before switching from the PWA if existing financial records need to be moved.

## Migration roadmap

1. Foundation: onboarding, preferences, navigation, local transaction storage.
2. Data migration: import/export the PWA backup format, categories, income, recurring transactions, and receipt metadata.
3. Finance features: budgets, savings goals, recurring expenses/income, installments, split bills, tags, and daily notes.
4. Reports and Date: report filters/charts, Date wishlist and shared spending.
5. System integration: local notifications, reminders, profile photo, CSV/PDF export, and accessibility polish.

The native project deliberately lives under ios/; it does not replace or modify the web app.
