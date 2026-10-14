import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped eligibility slots through their life cycle and keeps a journal of what it did.
    final class CappedEligibilitySlotService {
        var store: any CappedEligibilitySlotStore
        var validator: CappedEligibilitySlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedEligibilitySlotStore, validator: CappedEligibilitySlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped eligibility slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedEligibilitySlotStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped eligibility slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedEligibilitySlotStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newCappedEligibilitySlotService(_ store: any CappedEligibilitySlotStore, clock: any Kit.Clocks.Clock) -> CappedEligibilitySlotService {
        return CappedEligibilitySlotService(
            store: store,
            validator: defaultCappedEligibilitySlotValidator(),
            clock: clock,
            journal: []
        )
    }
}
