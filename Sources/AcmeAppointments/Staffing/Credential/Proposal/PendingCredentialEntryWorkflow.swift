import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending credential entries through their life cycle and keeps a journal of what it did.
    final class PendingCredentialEntryCoordinator {
        var store: any PendingCredentialEntryStore
        var validator: PendingCredentialEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingCredentialEntryStore, validator: PendingCredentialEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending credential entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCredentialEntryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending credential entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCredentialEntryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newPendingCredentialEntryCoordinator(_ store: any PendingCredentialEntryStore, clock: any Kit.Clocks.Clock) -> PendingCredentialEntryCoordinator {
        return PendingCredentialEntryCoordinator(
            store: store,
            validator: defaultPendingCredentialEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
