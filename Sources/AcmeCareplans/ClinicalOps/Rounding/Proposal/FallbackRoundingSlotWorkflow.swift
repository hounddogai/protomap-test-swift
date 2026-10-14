import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves fallback rounding slots through their life cycle and keeps a journal of what it did.
    final class FallbackRoundingSlotService {
        var store: any FallbackRoundingSlotStore
        var validator: FallbackRoundingSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackRoundingSlotEngine

        init(store: any FallbackRoundingSlotStore, validator: FallbackRoundingSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackRoundingSlotEngine) {
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
                throw Kit.Failure("fallback rounding slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackRoundingSlotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback rounding slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackRoundingSlotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback rounding slot \(code) not found")
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

    static func newFallbackRoundingSlotService(_ store: any FallbackRoundingSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackRoundingSlotService {
        return FallbackRoundingSlotService(
            store: store,
            validator: defaultFallbackRoundingSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackRoundingSlotEngine(flags)
        )
    }
}
