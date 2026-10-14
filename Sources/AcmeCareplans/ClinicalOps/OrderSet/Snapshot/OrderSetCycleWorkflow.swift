import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set cycles through their life cycle and keeps a journal of what it did.
    final class OrderSetCycleService {
        var store: any OrderSetCycleStore
        var validator: OrderSetCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OrderSetCycleEngine

        init(store: any OrderSetCycleStore, validator: OrderSetCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OrderSetCycleEngine) {
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
                throw Kit.Failure("order set cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetCycleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetCycleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set cycle \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newOrderSetCycleService(_ store: any OrderSetCycleStore, clock: any Kit.Clocks.Clock) -> OrderSetCycleService {
        return OrderSetCycleService(
            store: store,
            validator: defaultOrderSetCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultOrderSetCycleEngine()
        )
    }
}
