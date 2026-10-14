import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set allocations through their life cycle and keeps a journal of what it did.
    final class OrderSetAllocationWorkflow {
        var store: any OrderSetAllocationStore
        var validator: OrderSetAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OrderSetAllocationEngine

        init(store: any OrderSetAllocationStore, validator: OrderSetAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OrderSetAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetAllocationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetAllocationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set allocation \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newOrderSetAllocationWorkflow(_ store: any OrderSetAllocationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OrderSetAllocationWorkflow {
        return OrderSetAllocationWorkflow(
            store: store,
            validator: defaultOrderSetAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultOrderSetAllocationEngine(flags)
        )
    }
}
