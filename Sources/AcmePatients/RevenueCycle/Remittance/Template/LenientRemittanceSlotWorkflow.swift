import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient remittance slots through their life cycle and keeps a journal of what it did.
    final class LenientRemittanceSlotDesk {
        var store: any LenientRemittanceSlotStore
        var validator: LenientRemittanceSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientRemittanceSlotEngine

        init(store: any LenientRemittanceSlotStore, validator: LenientRemittanceSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientRemittanceSlotEngine) {
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
                throw Kit.Failure("lenient remittance slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRemittanceSlotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRemittanceSlotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance slot \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newLenientRemittanceSlotDesk(_ store: any LenientRemittanceSlotStore, clock: any Kit.Clocks.Clock) -> LenientRemittanceSlotDesk {
        return LenientRemittanceSlotDesk(
            store: store,
            validator: defaultLenientRemittanceSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientRemittanceSlotEngine()
        )
    }
}
