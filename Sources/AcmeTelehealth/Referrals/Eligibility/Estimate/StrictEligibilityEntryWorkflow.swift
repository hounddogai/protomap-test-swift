import AcmePlatform
import Foundation

extension Referrals {
    /// Moves strict eligibility entries through their life cycle and keeps a journal of what it did.
    final class StrictEligibilityEntryDesk {
        var store: any StrictEligibilityEntryStore
        var validator: StrictEligibilityEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictEligibilityEntryStore, validator: StrictEligibilityEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict eligibility entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictEligibilityEntryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict eligibility entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictEligibilityEntryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newStrictEligibilityEntryDesk(_ store: any StrictEligibilityEntryStore, clock: any Kit.Clocks.Clock) -> StrictEligibilityEntryDesk {
        return StrictEligibilityEntryDesk(
            store: store,
            validator: defaultStrictEligibilityEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
