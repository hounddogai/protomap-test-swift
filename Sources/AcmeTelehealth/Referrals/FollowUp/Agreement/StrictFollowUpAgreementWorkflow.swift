import AcmePlatform
import Foundation

extension Referrals {
    /// Moves strict follow up agreements through their life cycle and keeps a journal of what it did.
    final class StrictFollowUpAgreementManager {
        var store: any StrictFollowUpAgreementStore
        var validator: StrictFollowUpAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictFollowUpAgreementStore, validator: StrictFollowUpAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict follow up agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictFollowUpAgreementStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict follow up agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictFollowUpAgreementStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newStrictFollowUpAgreementManager(_ store: any StrictFollowUpAgreementStore, clock: any Kit.Clocks.Clock) -> StrictFollowUpAgreementManager {
        return StrictFollowUpAgreementManager(
            store: store,
            validator: defaultStrictFollowUpAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
