import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves discharge plan tiers through their life cycle and keeps a journal of what it did.
    final class DischargePlanTierDesk {
        var store: any DischargePlanTierStore
        var validator: DischargePlanTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DischargePlanTierEngine

        init(store: any DischargePlanTierStore, validator: DischargePlanTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DischargePlanTierEngine) {
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
                throw Kit.Failure("discharge plan tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DischargePlanTierStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DischargePlanTierStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan tier \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newDischargePlanTierDesk(_ store: any DischargePlanTierStore, clock: any Kit.Clocks.Clock) -> DischargePlanTierDesk {
        return DischargePlanTierDesk(
            store: store,
            validator: defaultDischargePlanTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultDischargePlanTierEngine()
        )
    }
}
