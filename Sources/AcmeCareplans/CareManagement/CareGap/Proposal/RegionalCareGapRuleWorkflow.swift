import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves regional care gap rules through their life cycle and keeps a journal of what it did.
    final class RegionalCareGapRuleService {
        var store: any RegionalCareGapRuleStore
        var validator: RegionalCareGapRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalCareGapRuleEngine

        init(store: any RegionalCareGapRuleStore, validator: RegionalCareGapRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalCareGapRuleEngine) {
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
                throw Kit.Failure("regional care gap rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalCareGapRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional care gap rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalCareGapRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional care gap rule \(code) not found")
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

    static func newRegionalCareGapRuleService(_ store: any RegionalCareGapRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalCareGapRuleService {
        return RegionalCareGapRuleService(
            store: store,
            validator: defaultRegionalCareGapRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalCareGapRuleEngine(flags)
        )
    }
}
