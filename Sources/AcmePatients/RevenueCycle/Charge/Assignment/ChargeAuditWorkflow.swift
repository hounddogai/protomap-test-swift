import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge audits through their life cycle and keeps a journal of what it did.
    final class ChargeAuditWorkflow {
        var store: any ChargeAuditStore
        var validator: ChargeAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeAuditEngine

        init(store: any ChargeAuditStore, validator: ChargeAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeAuditEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeAuditStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeAuditStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge audit \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newChargeAuditWorkflow(_ store: any ChargeAuditStore, clock: any Kit.Clocks.Clock) -> ChargeAuditWorkflow {
        return ChargeAuditWorkflow(
            store: store,
            validator: defaultChargeAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeAuditEngine()
        )
    }
}
