import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves seasonal statement policies through their life cycle and keeps a journal of what it did.
    final class SeasonalStatementPolicyManager {
        var store: any SeasonalStatementPolicyStore
        var validator: SeasonalStatementPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalStatementPolicyStore, validator: SeasonalStatementPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal statement policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalStatementPolicyStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal statement policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalStatementPolicyStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newSeasonalStatementPolicyManager(_ store: any SeasonalStatementPolicyStore, clock: any Kit.Clocks.Clock) -> SeasonalStatementPolicyManager {
        return SeasonalStatementPolicyManager(
            store: store,
            validator: defaultSeasonalStatementPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
