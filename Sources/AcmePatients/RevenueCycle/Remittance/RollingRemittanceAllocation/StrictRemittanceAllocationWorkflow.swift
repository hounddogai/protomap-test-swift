import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves strict remittance allocations through their life cycle and keeps a journal of what it did.
    final class StrictRemittanceAllocationWorkflow {
        var store: any StrictRemittanceAllocationStore
        var validator: StrictRemittanceAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictRemittanceAllocationEngine

        init(store: any StrictRemittanceAllocationStore, validator: StrictRemittanceAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictRemittanceAllocationEngine) {
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
                throw Kit.Failure("strict remittance allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictRemittanceAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict remittance allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictRemittanceAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict remittance allocation \(code) not found")
            }
            let result = engine.price(item)
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

    static func newStrictRemittanceAllocationWorkflow(_ store: any StrictRemittanceAllocationStore, clock: any Kit.Clocks.Clock) -> StrictRemittanceAllocationWorkflow {
        return StrictRemittanceAllocationWorkflow(
            store: store,
            validator: defaultStrictRemittanceAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictRemittanceAllocationEngine()
        )
    }
}
