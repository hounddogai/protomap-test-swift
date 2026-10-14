import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility mappings through their life cycle and keeps a journal of what it did.
    final class EligibilityMappingDesk {
        var store: any EligibilityMappingStore
        var validator: EligibilityMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityMappingEngine

        init(store: any EligibilityMappingStore, validator: EligibilityMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityMappingEngine) {
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
                throw Kit.Failure("eligibility mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityMappingStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityMappingStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility mapping \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newEligibilityMappingDesk(_ store: any EligibilityMappingStore, clock: any Kit.Clocks.Clock) -> EligibilityMappingDesk {
        return EligibilityMappingDesk(
            store: store,
            validator: defaultEligibilityMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityMappingEngine()
        )
    }
}
