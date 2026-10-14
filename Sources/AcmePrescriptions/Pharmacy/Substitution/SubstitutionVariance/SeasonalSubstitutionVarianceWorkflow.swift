import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves seasonal substitution variances through their life cycle and keeps a journal of what it did.
    final class SeasonalSubstitutionVarianceManager {
        var store: any SeasonalSubstitutionVarianceStore
        var validator: SeasonalSubstitutionVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalSubstitutionVarianceStore, validator: SeasonalSubstitutionVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal substitution variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalSubstitutionVarianceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal substitution variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalSubstitutionVarianceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newSeasonalSubstitutionVarianceManager(_ store: any SeasonalSubstitutionVarianceStore, clock: any Kit.Clocks.Clock) -> SeasonalSubstitutionVarianceManager {
        return SeasonalSubstitutionVarianceManager(
            store: store,
            validator: defaultSeasonalSubstitutionVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
