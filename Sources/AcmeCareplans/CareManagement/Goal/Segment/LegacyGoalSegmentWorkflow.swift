import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy goal segments through their life cycle and keeps a journal of what it did.
    final class LegacyGoalSegmentService {
        var store: any LegacyGoalSegmentStore
        var validator: LegacyGoalSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyGoalSegmentStore, validator: LegacyGoalSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy goal segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyGoalSegmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy goal segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyGoalSegmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newLegacyGoalSegmentService(_ store: any LegacyGoalSegmentStore, clock: any Kit.Clocks.Clock) -> LegacyGoalSegmentService {
        return LegacyGoalSegmentService(
            store: store,
            validator: defaultLegacyGoalSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
