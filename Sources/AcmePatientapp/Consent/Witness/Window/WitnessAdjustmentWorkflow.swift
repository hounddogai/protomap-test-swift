import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness adjustments through their life cycle and keeps a journal of what it did.
    final class WitnessAdjustmentDesk {
        var store: any WitnessAdjustmentStore
        var validator: WitnessAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessAdjustmentEngine

        init(store: any WitnessAdjustmentStore, validator: WitnessAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessAdjustmentEngine) {
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
                throw Kit.Failure("witness adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessAdjustmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessAdjustmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness adjustment \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newWitnessAdjustmentDesk(_ store: any WitnessAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WitnessAdjustmentDesk {
        return WitnessAdjustmentDesk(
            store: store,
            validator: defaultWitnessAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessAdjustmentEngine(flags)
        )
    }
}
