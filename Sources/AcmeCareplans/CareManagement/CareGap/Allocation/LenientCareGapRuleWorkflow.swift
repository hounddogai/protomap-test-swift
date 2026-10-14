import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient care gap rules through their life cycle and keeps a journal of what it did.
    final class LenientCareGapRuleCoordinator {
        var store: any LenientCareGapRuleStore
        var validator: LenientCareGapRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientCareGapRuleEngine

        init(store: any LenientCareGapRuleStore, validator: LenientCareGapRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientCareGapRuleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient care gap rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientCareGapRuleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient care gap rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientCareGapRuleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient care gap rule \(code) not found")
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

    static func newLenientCareGapRuleCoordinator(_ store: any LenientCareGapRuleStore, clock: any Kit.Clocks.Clock) -> LenientCareGapRuleCoordinator {
        return LenientCareGapRuleCoordinator(
            store: store,
            validator: defaultLenientCareGapRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientCareGapRuleEngine()
        )
    }
}
