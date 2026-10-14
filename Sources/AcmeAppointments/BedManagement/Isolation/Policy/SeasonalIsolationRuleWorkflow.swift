import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves seasonal isolation rules through their life cycle and keeps a journal of what it did.
    final class SeasonalIsolationRuleService {
        var store: any SeasonalIsolationRuleStore
        var validator: SeasonalIsolationRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalIsolationRuleStore, validator: SeasonalIsolationRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal isolation rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalIsolationRuleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal isolation rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalIsolationRuleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newSeasonalIsolationRuleService(_ store: any SeasonalIsolationRuleStore, clock: any Kit.Clocks.Clock) -> SeasonalIsolationRuleService {
        return SeasonalIsolationRuleService(
            store: store,
            validator: defaultSeasonalIsolationRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
