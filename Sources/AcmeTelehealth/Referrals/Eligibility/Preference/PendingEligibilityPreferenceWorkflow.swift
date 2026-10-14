import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending eligibility preferences through their life cycle and keeps a journal of what it did.
    final class PendingEligibilityPreferenceManager {
        var store: any PendingEligibilityPreferenceStore
        var validator: PendingEligibilityPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingEligibilityPreferenceStore, validator: PendingEligibilityPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending eligibility preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingEligibilityPreferenceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending eligibility preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingEligibilityPreferenceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newPendingEligibilityPreferenceManager(_ store: any PendingEligibilityPreferenceStore, clock: any Kit.Clocks.Clock) -> PendingEligibilityPreferenceManager {
        return PendingEligibilityPreferenceManager(
            store: store,
            validator: defaultPendingEligibilityPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
