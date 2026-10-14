import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning preferences through their life cycle and keeps a journal of what it did.
    final class CleaningPreferenceWorkflow {
        var store: any CleaningPreferenceStore
        var validator: CleaningPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CleaningPreferenceStore, validator: CleaningPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("cleaning preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningPreferenceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningPreferenceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newCleaningPreferenceWorkflow(_ store: any CleaningPreferenceStore, clock: any Kit.Clocks.Clock) -> CleaningPreferenceWorkflow {
        return CleaningPreferenceWorkflow(
            store: store,
            validator: defaultCleaningPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
