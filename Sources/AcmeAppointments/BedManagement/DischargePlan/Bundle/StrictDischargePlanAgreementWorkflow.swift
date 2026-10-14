import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves strict discharge plan agreements through their life cycle and keeps a journal of what it did.
    final class StrictDischargePlanAgreementManager {
        var store: any StrictDischargePlanAgreementStore
        var validator: StrictDischargePlanAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictDischargePlanAgreementStore, validator: StrictDischargePlanAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict discharge plan agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictDischargePlanAgreementStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict discharge plan agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictDischargePlanAgreementStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newStrictDischargePlanAgreementManager(_ store: any StrictDischargePlanAgreementStore, clock: any Kit.Clocks.Clock) -> StrictDischargePlanAgreementManager {
        return StrictDischargePlanAgreementManager(
            store: store,
            validator: defaultStrictDischargePlanAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
