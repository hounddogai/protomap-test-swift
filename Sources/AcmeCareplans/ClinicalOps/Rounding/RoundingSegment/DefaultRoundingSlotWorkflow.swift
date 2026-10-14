import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves default rounding slots through their life cycle and keeps a journal of what it did.
    final class DefaultRoundingSlotCoordinator {
        var store: any DefaultRoundingSlotStore
        var validator: DefaultRoundingSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultRoundingSlotEngine

        init(store: any DefaultRoundingSlotStore, validator: DefaultRoundingSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultRoundingSlotEngine) {
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
                throw Kit.Failure("default rounding slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultRoundingSlotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default rounding slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultRoundingSlotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default rounding slot \(code) not found")
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

    static func newDefaultRoundingSlotCoordinator(_ store: any DefaultRoundingSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultRoundingSlotCoordinator {
        return DefaultRoundingSlotCoordinator(
            store: store,
            validator: defaultDefaultRoundingSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultRoundingSlotEngine(flags)
        )
    }
}
