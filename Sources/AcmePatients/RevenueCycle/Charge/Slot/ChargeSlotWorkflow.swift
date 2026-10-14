import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge slots through their life cycle and keeps a journal of what it did.
    final class ChargeSlotService {
        var store: any ChargeSlotStore
        var validator: ChargeSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeSlotEngine

        init(store: any ChargeSlotStore, validator: ChargeSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeSlotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeSlotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeSlotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge slot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newChargeSlotService(_ store: any ChargeSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ChargeSlotService {
        return ChargeSlotService(
            store: store,
            validator: defaultChargeSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeSlotEngine(flags)
        )
    }
}
