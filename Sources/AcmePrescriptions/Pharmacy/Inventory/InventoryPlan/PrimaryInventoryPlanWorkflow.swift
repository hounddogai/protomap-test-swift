import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves primary inventory plans through their life cycle and keeps a journal of what it did.
    final class PrimaryInventoryPlanDesk {
        var store: any PrimaryInventoryPlanStore
        var validator: PrimaryInventoryPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryInventoryPlanEngine

        init(store: any PrimaryInventoryPlanStore, validator: PrimaryInventoryPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryInventoryPlanEngine) {
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
                throw Kit.Failure("primary inventory plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryInventoryPlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary inventory plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryInventoryPlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary inventory plan \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPrimaryInventoryPlanDesk(_ store: any PrimaryInventoryPlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryInventoryPlanDesk {
        return PrimaryInventoryPlanDesk(
            store: store,
            validator: defaultPrimaryInventoryPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryInventoryPlanEngine(flags)
        )
    }
}
