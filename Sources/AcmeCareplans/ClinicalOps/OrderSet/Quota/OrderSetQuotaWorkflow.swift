import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set quotas through their life cycle and keeps a journal of what it did.
    final class OrderSetQuotaManager {
        var store: any OrderSetQuotaStore
        var validator: OrderSetQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OrderSetQuotaEngine

        init(store: any OrderSetQuotaStore, validator: OrderSetQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OrderSetQuotaEngine) {
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
                throw Kit.Failure("order set quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetQuotaStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetQuotaStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set quota \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newOrderSetQuotaManager(_ store: any OrderSetQuotaStore, clock: any Kit.Clocks.Clock) -> OrderSetQuotaManager {
        return OrderSetQuotaManager(
            store: store,
            validator: defaultOrderSetQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultOrderSetQuotaEngine()
        )
    }
}
