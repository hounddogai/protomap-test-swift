import AcmePlatform
import Foundation

extension Referrals {
    /// Moves default follow up variances through their life cycle and keeps a journal of what it did.
    final class DefaultFollowUpVarianceCoordinator {
        var store: any DefaultFollowUpVarianceStore
        var validator: DefaultFollowUpVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultFollowUpVarianceEngine

        init(store: any DefaultFollowUpVarianceStore, validator: DefaultFollowUpVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultFollowUpVarianceEngine) {
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
                throw Kit.Failure("default follow up variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultFollowUpVarianceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default follow up variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultFollowUpVarianceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default follow up variance \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newDefaultFollowUpVarianceCoordinator(_ store: any DefaultFollowUpVarianceStore, clock: any Kit.Clocks.Clock) -> DefaultFollowUpVarianceCoordinator {
        return DefaultFollowUpVarianceCoordinator(
            store: store,
            validator: defaultDefaultFollowUpVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultFollowUpVarianceEngine()
        )
    }
}
