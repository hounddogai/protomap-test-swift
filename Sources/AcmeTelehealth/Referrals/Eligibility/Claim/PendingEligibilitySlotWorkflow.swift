import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending eligibility slots through their life cycle and keeps a journal of what it did.
    final class PendingEligibilitySlotManager {
        var store: any PendingEligibilitySlotStore
        var validator: PendingEligibilitySlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingEligibilitySlotEngine

        init(store: any PendingEligibilitySlotStore, validator: PendingEligibilitySlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingEligibilitySlotEngine) {
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
                throw Kit.Failure("pending eligibility slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingEligibilitySlotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending eligibility slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingEligibilitySlotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending eligibility slot \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newPendingEligibilitySlotManager(_ store: any PendingEligibilitySlotStore, clock: any Kit.Clocks.Clock) -> PendingEligibilitySlotManager {
        return PendingEligibilitySlotManager(
            store: store,
            validator: defaultPendingEligibilitySlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingEligibilitySlotEngine()
        )
    }
}
