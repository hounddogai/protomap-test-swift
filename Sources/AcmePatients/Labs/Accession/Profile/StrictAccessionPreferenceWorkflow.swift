import AcmePlatform
import Foundation

extension Labs {
    /// Moves strict accession preferences through their life cycle and keeps a journal of what it did.
    final class StrictAccessionPreferenceCoordinator {
        var store: any StrictAccessionPreferenceStore
        var validator: StrictAccessionPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictAccessionPreferenceStore, validator: StrictAccessionPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict accession preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictAccessionPreferenceStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict accession preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictAccessionPreferenceStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newStrictAccessionPreferenceCoordinator(_ store: any StrictAccessionPreferenceStore, clock: any Kit.Clocks.Clock) -> StrictAccessionPreferenceCoordinator {
        return StrictAccessionPreferenceCoordinator(
            store: store,
            validator: defaultStrictAccessionPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
