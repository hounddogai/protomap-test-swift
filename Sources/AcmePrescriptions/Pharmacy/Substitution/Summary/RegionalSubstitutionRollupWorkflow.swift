import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves regional substitution rollups through their life cycle and keeps a journal of what it did.
    final class RegionalSubstitutionRollupManager {
        var store: any RegionalSubstitutionRollupStore
        var validator: RegionalSubstitutionRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalSubstitutionRollupStore, validator: RegionalSubstitutionRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional substitution rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalSubstitutionRollupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional substitution rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalSubstitutionRollupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newRegionalSubstitutionRollupManager(_ store: any RegionalSubstitutionRollupStore, clock: any Kit.Clocks.Clock) -> RegionalSubstitutionRollupManager {
        return RegionalSubstitutionRollupManager(
            store: store,
            validator: defaultRegionalSubstitutionRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
