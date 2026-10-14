import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves discharge plan variances through their life cycle and keeps a journal of what it did.
    final class DischargePlanVarianceManager {
        var store: any DischargePlanVarianceStore
        var validator: DischargePlanVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DischargePlanVarianceStore, validator: DischargePlanVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("discharge plan variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DischargePlanVarianceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("discharge plan variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DischargePlanVarianceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newDischargePlanVarianceManager(_ store: any DischargePlanVarianceStore, clock: any Kit.Clocks.Clock) -> DischargePlanVarianceManager {
        return DischargePlanVarianceManager(
            store: store,
            validator: defaultDischargePlanVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
