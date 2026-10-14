import AcmePlatform
import Foundation

extension Referrals {
    /// Moves global slot estimates through their life cycle and keeps a journal of what it did.
    final class GlobalSlotEstimateService {
        var store: any GlobalSlotEstimateStore
        var validator: GlobalSlotEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalSlotEstimateEngine

        init(store: any GlobalSlotEstimateStore, validator: GlobalSlotEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalSlotEstimateEngine) {
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
                throw Kit.Failure("global slot estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalSlotEstimateStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global slot estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalSlotEstimateStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global slot estimate \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newGlobalSlotEstimateService(_ store: any GlobalSlotEstimateStore, clock: any Kit.Clocks.Clock) -> GlobalSlotEstimateService {
        return GlobalSlotEstimateService(
            store: store,
            validator: defaultGlobalSlotEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalSlotEstimateEngine()
        )
    }
}
