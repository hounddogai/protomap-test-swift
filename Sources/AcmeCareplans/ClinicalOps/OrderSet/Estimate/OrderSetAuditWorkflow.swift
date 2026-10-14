import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set audits through their life cycle and keeps a journal of what it did.
    final class OrderSetAuditService {
        var store: any OrderSetAuditStore
        var validator: OrderSetAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OrderSetAuditStore, validator: OrderSetAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newOrderSetAuditService(_ store: any OrderSetAuditStore, clock: any Kit.Clocks.Clock) -> OrderSetAuditService {
        return OrderSetAuditService(
            store: store,
            validator: defaultOrderSetAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
