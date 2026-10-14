import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending authorization preferences through their life cycle and keeps a journal of what it did.
    final class PendingAuthorizationPreferenceDesk {
        var store: any PendingAuthorizationPreferenceStore
        var validator: PendingAuthorizationPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingAuthorizationPreferenceStore, validator: PendingAuthorizationPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending authorization preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingAuthorizationPreferenceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending authorization preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingAuthorizationPreferenceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newPendingAuthorizationPreferenceDesk(_ store: any PendingAuthorizationPreferenceStore, clock: any Kit.Clocks.Clock) -> PendingAuthorizationPreferenceDesk {
        return PendingAuthorizationPreferenceDesk(
            store: store,
            validator: defaultPendingAuthorizationPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
