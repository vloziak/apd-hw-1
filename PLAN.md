# Plan

## Scope

In this homework I make StudyPlanner package work by replacing `fatalError` placeholders with real logic. I don't rename anything in the
public API and I don't change starter tests. I work one task at a time,
and each task below has its implementation steps, risks
and test results.

## Task 1 Validation and errors

Task 1 works when item with empty title, or title made only of
spaces, tabs or new lines, fails with `blankTitle`. An item with zero or
negative minutes has to fail with `nonPositiveEstimatedMinutes`. If both the
title and the minutes are wrong at the same time, I still expect `blankTitle`,
because the title is checked first. When everything is correct, the item
should keep exactly the values I passed in.

### Implementation steps

For Task 1 I only worked in `StudyItem.init` inside
`Sources/StudyPlanner/StudyPlanner.swift`. First I trim whitespace from title and use `guard` to make sure something is left. 
After that I use second `guard` to check that minutes are more than zero. Only when both
checks pass do I save values into the properties.

### Risks

I trim the title only to check it, but I save original title. I chose this
so that `item.title` is always the same as what was passed in, and the hidden
tests don't get a different string back. The order of checks also really
matters, because if I ever swapped them, an item with both problems would
throw wrong error.

### `swift test` verification

I ran
```
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % swift test --filter "testValidItemStoresValues|testBlankTitleIsRejected"
Building for debugging...
[1/1] Write swift-version--1B3F06B94CC9E375.txt
Build complete! (0.11s)
Test Suite 'Selected tests' started at 2026-10-01 16:30:56.612.
Test Suite 'StudyPlannerPackageTests.xctest' started at 2026-10-01 16:30:56.612.
Test Suite 'StudyPlannerPublicTests' started at 2026-10-01 16:30:56.612.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' passed (0.000 seconds).
Test Suite 'StudyPlannerPublicTests' passed at 2026-10-01 16:30:56.613.
     Executed 2 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'StudyPlannerVictoriaTests' started at 2026-10-01 16:30:56.613.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testBlankTitleIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testBlankTitleIsRejected]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testValidItemStoresValues]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testValidItemStoresValues]' passed (0.000 seconds).
Test Suite 'StudyPlannerVictoriaTests' passed at 2026-10-01 16:30:56.613.
     Executed 2 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'StudyPlannerPackageTests.xctest' passed at 2026-10-01 16:30:56.613.
     Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.001) seconds
Test Suite 'Selected tests' passed at 2026-10-01 16:30:56.613.
     Executed 4 tests, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
◇ Test run started.
↳ Testing Library Version: 1902
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.
```

## Task 2 Codable boundaries

Task 2 works when a `StudyItem` that comes from JSON goes through the same
checks as one created in code. So JSON with a blank title has to fail with
`blankTitle`, and JSON with zero or negative minutes has to fail with
`nonPositiveEstimatedMinutes`. A `StudyPlan` should be readable from a JSON
object that keeps the list under the `items` key, and `StudyPlan.decode(from:)`
should read a JSON file that is just a plain array of items, like
`Fixtures/study-items.json`. If `isCompleted` is missing in the JSON, the item
should be treated as not completed.

### Implementation steps

For Task 2 I again worked only in `Sources/StudyPlanner/StudyPlanner.swift`.
In `StudyItem` I added private `CodingKeys` and my own `init(from decoder:)`.
It reads every field from the JSON and then calls my validating initializer
from Task 1, so I don't repeat the checks and they can't be skipped. I read
`isCompleted` with `decodeIfPresent` and use `false` when it's not there.
In `StudyPlan` I added a `CodingKeys` with one key, `items`, and an
`init(from decoder:)` that reads the array under that key and passes it to
`init(items:)`. Finally, in `decode(from:)` I use `JSONDecoder` to read a
plain array of `StudyItem` and build the plan with `StudyPlan(items:)`

### Risks

The automatic Codable code that Swift generates writes values straight into
the properties and never calls my initializer, so without my own
`init(from decoder:)` invalid JSON would quietly create invalid items. Both
ways of decoding a plan end in `init(items:)`, which is good because the
duplicate and ordering rules from Task 3 will apply to JSON automatically.
For now `init(items:)` is only a temporary `self.items = items` so I could
build and check Task 2. I will replace it with the real logic in Task 3. I
also kept the `CodingKeys` private, so the public API stays the same.

### `swift test` verification

I ran
```
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % swift build                                                             
[1/1] Planning build
Building for debugging...
[1/1] Write swift-version--1B3F06B94CC9E375.txt
Build complete! (0.16s)
```

## Task 3 Duplicates and ordering

Task 3 works when a plan that has two items with the same `id` fails with
`duplicateID`, and the error carries the first id that repeats while going
through the list from start to end. For example, with ids `a, b, b, a` the
error has to be `duplicateID("b")`, because the second `b` shows up before the
second `a`. When there are no duplicates, the items in the plan are always
sorted by title, and items with the same title are sorted by id, so the same
input always gives the same order.

### Implementation steps

For Task 3 I worked only in `StudyPlan.init(items:)` inside
`Sources/StudyPlanner/StudyPlanner.swift`, and I removed the temporary
`self.items = items` from Task 2. First I go through the items in the order
they came in and keep the ids I've already seen in a `Set`. As soon as I meet
an id that is already in the set, I throw `duplicateID` with that id. If the
loop finishes without errors, I sort the items by comparing `(title, id)`
tuples, so Swift compares the titles first and only looks at the ids when the
titles are equal. Then I save the sorted array into `items`.

### Risks

I have to look for duplicates before sorting, because sorting changes the
order and then a different id could look like the first duplicate. Sorting
only by title would not be enough, since two items with the same title could
end up in any order, so I added the id as a second rule. Swift compares
strings with case, so for example `"Zebra"` comes before `"apple"`. I kept the
default comparison because the task doesn't ask for anything else. Both ways
of decoding a plan from Task 2 go through `init(items:)`, so JSON input now
gets the same duplicate check and the same order.

### `swift test` verification

I ran
```
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % swift build
Building for debugging...
[4/4] Compiling StudyPlanner StudyPlanner.swift
Build complete! (0.65s)
```
and had another error on swift test `Fatal error: Implement completion mutation`
```
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % swift test                                                              
[1/1] Planning build
Building for debugging...
[3/3] Linking StudyPlannerPackageTests
Build complete! (0.74s)
Test Suite 'All tests' started at 2026-10-01 17:27:02.438.
Test Suite 'StudyPlannerPackageTests.xctest' started at 2026-10-01 17:27:02.442.
Test Suite 'StudyPlannerPublicTests' started at 2026-10-01 17:27:02.442.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' passed (0.002 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testIncompleteMinutesAndCompletion]' started.
StudyPlanner/StudyPlanner.swift:107: Fatal error: Implement completion mutation
error: Process '/Users/victorialozak/Downloads/Xcode.app/Contents/Developer/usr/bin/xctest /Users/victorialozak/Documents/GitHub/apd-hw-1/.build/arm64-apple-macosx/debug/StudyPlannerPackageTests.xctest' exited with unexpected signal code 5
◇ Test run started.
↳ Testing Library Version: 1902
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % 
```

## Task 4 Queries and completion

Task 4 works when `items(in:)` returns only the items from the category I ask
for, and keeps them in the same sorted order as the plan. `incompleteMinutes()`
has to add up the minutes of the items that are not completed yet, and return
`0` when there are none. `markCompleted(id:)` has to mark the item with that id
as completed, and if there is no item with that id it has to throw
`unknownID` with the same id. Marking an item that is already completed must
not throw and must not change anything else, so calling it twice gives the
same result as calling it once.

### Implementation steps

For `items(in:)` I use `filter` to keep only the items with the matching
category. For `incompleteMinutes()` I first `filter` out the completed items
and then use `reduce` starting from `0` to add up `estimatedMinutes`. For
`markCompleted(id:)` I look for the position of the item with `firstIndex`,
and if it's not found I throw `unknownID(id)` from a `guard`. I couldn't set
`isCompleted` directly from `StudyPlan`, because it is `private(set)` inside
`StudyItem`. So I added a small internal `mutating func markAsCompleted()` to
`StudyItem`. It's not `public`, so the public API stays the same.

### Risks

`isCompleted` can only be changed inside `StudyItem`, so the new helper method
is the only way the plan changes it. I left the helper without `public` on
purpose, so it doesn't become part of the public API. Marking an item as
completed doesn't change its title or id, so the title-then-id order from
Task 3 stays correct. Completion is idempotent because the method only sets
`isCompleted` to `true`, so a second call changes nothing and doesn't throw.

### `swift test` verification

 I ran  
```
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % swift build
[1/1] Planning build
Building for debugging...
[1/1] Write swift-version--1B3F06B94CC9E375.txt
Build complete! (0.16s)
```
```
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % swift test 
[1/1] Planning build
Building for debugging...
[1/1] Write swift-version--1B3F06B94CC9E375.txt
Build complete! (0.15s)
Test Suite 'All tests' started at 2026-10-01 17:42:19.303.
Test Suite 'StudyPlannerPackageTests.xctest' started at 2026-10-01 17:42:19.308.
Test Suite 'StudyPlannerPublicTests' started at 2026-10-01 17:42:19.308.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' passed (0.003 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testIncompleteMinutesAndCompletion]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testIncompleteMinutesAndCompletion]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' passed (0.000 seconds).
Test Suite 'StudyPlannerPublicTests' passed at 2026-10-01 17:42:19.311.
     Executed 3 tests, with 0 failures (0 unexpected) in 0.003 (0.003) seconds
Test Suite 'StudyPlannerVictoriaTests' started at 2026-10-01 17:42:19.311.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testBlankTitleIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testBlankTitleIsRejected]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testIncompleteMinutesAndCompletion]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testIncompleteMinutesAndCompletion]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testValidItemStoresValues]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testValidItemStoresValues]' passed (0.000 seconds).
Test Suite 'StudyPlannerVictoriaTests' passed at 2026-10-01 17:42:19.312.
     Executed 3 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
Test Suite 'StudyPlannerPackageTests.xctest' passed at 2026-10-01 17:42:19.312.
     Executed 6 tests, with 0 failures (0 unexpected) in 0.003 (0.003) seconds
Test Suite 'All tests' passed at 2026-10-01 17:42:19.312.
     Executed 6 tests, with 0 failures (0 unexpected) in 0.003 (0.008) seconds
◇ Test run started.
↳ Testing Library Version: 1902
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.
```
All public tests passed. 

## Task 5 My tests

I replaced my first test file, which was copy of the starter tests, with
twelve new tests in `StudyPlannerVictoriaTests`. Each task from 1 to 4 has its
own group of tests, so if something breaks later I can see which part it is.

### Implementation steps

I added a small private helper `makeItem` with default values, so each test
only shows the values that matter for it. For Task 1 I test zero minutes, the
title-before-minutes rule, and that a title with spaces around it is kept as
it is. For Task 2 I decode an item with a blank title from JSON, a plan from a
JSON object with the `items` key, and the `study-items.json` fixture. For
Task 3 I test that `a, b, b, a` reports `b`, and that items are sorted by
title and then by id. For Task 4 I test the category query, zero minutes for
an empty plan, an unknown id that throws and leaves the plan unchanged, and
that completing the same item twice gives the same result.

### Risks

In the sorting test I pass the items in the wrong
order on purpose, otherwise it would pass even without sorting. For errors I
check the exact error case and not only that something was thrown, because
the grader checks the exact errors too. 

### `swift test` verification

I ran 

```
victorialozak@MacBook-Pro-Viktoria apd-hw-1 % swift test                                   
Building for debugging...
[1/1] Write swift-version--1B3F06B94CC9E375.txt
Build complete! (0.14s)
Test Suite 'All tests' started at 2026-10-01 17:54:10.555.
Test Suite 'StudyPlannerPackageTests.xctest' started at 2026-10-01 17:54:10.557.
Test Suite 'StudyPlannerPublicTests' started at 2026-10-01 17:54:10.557.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testBlankTitleIsRejected]' passed (0.002 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testIncompleteMinutesAndCompletion]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testIncompleteMinutesAndCompletion]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' started.
Test Case '-[StudyPlannerTests.StudyPlannerPublicTests testValidItemStoresValues]' passed (0.000 seconds).
Test Suite 'StudyPlannerPublicTests' passed at 2026-10-01 17:54:10.559.
     Executed 3 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'StudyPlannerVictoriaTests' started at 2026-10-01 17:54:10.559.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testDecodingFixtureArray]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testDecodingFixtureArray]' passed (0.001 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testDecodingItemWithBlankTitleFails]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testDecodingItemWithBlankTitleFails]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testDecodingKeyedPlanUsesItemsKey]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testDecodingKeyedPlanUsesItemsKey]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testFirstDuplicateIDIsReported]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testFirstDuplicateIDIsReported]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testIncompleteMinutesIsZeroForEmptyPlan]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testIncompleteMinutesIsZeroForEmptyPlan]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testItemsAreSortedByTitleThenID]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testItemsAreSortedByTitleThenID]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testItemsInCategoryReturnsOnlyThatCategory]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testItemsInCategoryReturnsOnlyThatCategory]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testMarkCompletedIsIdempotent]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testMarkCompletedIsIdempotent]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testMarkCompletedWithUnknownIDThrowsAndKeepsPlan]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testMarkCompletedWithUnknownIDThrowsAndKeepsPlan]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testTitleErrorTakesPrecedenceOverMinutes]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testTitleErrorTakesPrecedenceOverMinutes]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testTitleWithSurroundingSpacesIsKeptAsIs]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testTitleWithSurroundingSpacesIsKeptAsIs]' passed (0.000 seconds).
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testZeroMinutesIsRejected]' started.
Test Case '-[StudyPlannerTests.StudyPlannerVictoriaTests testZeroMinutesIsRejected]' passed (0.000 seconds).
Test Suite 'StudyPlannerVictoriaTests' passed at 2026-10-01 17:54:10.561.
     Executed 12 tests, with 0 failures (0 unexpected) in 0.002 (0.002) seconds
Test Suite 'StudyPlannerPackageTests.xctest' passed at 2026-10-01 17:54:10.561.
     Executed 15 tests, with 0 failures (0 unexpected) in 0.004 (0.004) seconds
Test Suite 'All tests' passed at 2026-10-01 17:54:10.561.
     Executed 15 tests, with 0 failures (0 unexpected) in 0.004 (0.006) seconds
◇ Test run started.
↳ Testing Library Version: 1902
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.
```
All tests passes.
