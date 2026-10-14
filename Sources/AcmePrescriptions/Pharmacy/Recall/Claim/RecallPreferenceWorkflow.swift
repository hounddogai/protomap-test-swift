import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall preferences through their life cycle and keeps a journal of what it did.
    final class RecallPreferenceService {
        var store: any RecallPreferenceStore
        var validator: RecallPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallPreferenceStore, validator: RecallPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("recall preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallPreferenceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallPreferenceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRecallPreferenceService(_ store: any RecallPreferenceStore, clock: any Kit.Clocks.Clock) -> RecallPreferenceService {
        return RecallPreferenceService(
            store: store,
            validator: defaultRecallPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
