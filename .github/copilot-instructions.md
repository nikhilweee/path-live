# General Instructions

- When generating code, prefer responses that are simple, short and elegant.
- When a something is getting too big, try breaking it up into smaller parts.
- After every change, make sure that the code is cohesive.

# Proofread Instructions

When asked to proofread, you are essentially being asked to take a look at the
entire file again and make sure that things are cohesive. Compared to
refactoring, proofreading involves relatively localised changes.

# Refactor Instructions

When asked to refactor, you are essentially being asked to take a look at the
entire project again to make sure that things are cohesive. Compared to
proofreading, refactoring typically involves moving things around.

- Make sure the new changes are in line with the rest of the project.
- If certain functionality is being repeated, please consolidate them.
- If a file is getting too big to handle, feel free to split it up.

# Project Overview

This is a high level overview of the app structure:

- Widgets are stored in `lib/widgets/*.dart`
- Models are stored in `lib/models/models.dart`
- Any utilities are stored in `lib/utils/*.dart`
