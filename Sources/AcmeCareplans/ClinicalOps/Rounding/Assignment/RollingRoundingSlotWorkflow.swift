import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rolling rounding slots through their life cycle and keeps a journal of what it did.
    final class RollingRoundingSlotDesk {
        var store: any RollingRoundingSlotStore
        var validator: RollingRoundingSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingRoundingSlotEngine

        init(store: any RollingRoundingSlotStore, validator: RollingRoundingSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingRoundingSlotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling rounding slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingRoundingSlotStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling rounding slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingRoundingSlotStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling rounding slot \(code) not found")
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

    static func newRollingRoundingSlotDesk(_ store: any RollingRoundingSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingRoundingSlotDesk {
        return RollingRoundingSlotDesk(
            store: store,
            validator: defaultRollingRoundingSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingRoundingSlotEngine(flags)
        )
    }
}
