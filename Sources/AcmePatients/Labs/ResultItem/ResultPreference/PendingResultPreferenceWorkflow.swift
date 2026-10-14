import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending result preferences through their life cycle and keeps a journal of what it did.
    final class PendingResultPreferenceManager {
        var store: any PendingResultPreferenceStore
        var validator: PendingResultPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingResultPreferenceStore, validator: PendingResultPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending result preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingResultPreferenceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending result preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingResultPreferenceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newPendingResultPreferenceManager(_ store: any PendingResultPreferenceStore, clock: any Kit.Clocks.Clock) -> PendingResultPreferenceManager {
        return PendingResultPreferenceManager(
            store: store,
            validator: defaultPendingResultPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
