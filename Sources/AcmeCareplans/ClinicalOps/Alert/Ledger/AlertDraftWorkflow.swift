import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert drafts through their life cycle and keeps a journal of what it did.
    final class AlertDraftDesk {
        var store: any AlertDraftStore
        var validator: AlertDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AlertDraftStore, validator: AlertDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("alert draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertDraftStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertDraftStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAlertDraftDesk(_ store: any AlertDraftStore, clock: any Kit.Clocks.Clock) -> AlertDraftDesk {
        return AlertDraftDesk(store: store, validator: defaultAlertDraftValidator(), clock: clock, journal: [])
    }
}
