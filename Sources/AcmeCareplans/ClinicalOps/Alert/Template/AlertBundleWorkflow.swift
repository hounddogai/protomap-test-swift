import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert bundles through their life cycle and keeps a journal of what it did.
    final class AlertBundleDesk {
        var store: any AlertBundleStore
        var validator: AlertBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AlertBundleStore, validator: AlertBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("alert bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertBundleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertBundleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newAlertBundleDesk(_ store: any AlertBundleStore, clock: any Kit.Clocks.Clock) -> AlertBundleDesk {
        return AlertBundleDesk(store: store, validator: defaultAlertBundleValidator(), clock: clock, journal: [])
    }
}
