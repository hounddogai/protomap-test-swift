import AcmePlatform
import Foundation

extension Consent {
    /// Moves default revocation milestones through their life cycle and keeps a journal of what it did.
    final class DefaultRevocationMilestoneManager {
        var store: any DefaultRevocationMilestoneStore
        var validator: DefaultRevocationMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultRevocationMilestoneStore, validator: DefaultRevocationMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default revocation milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultRevocationMilestoneStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default revocation milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultRevocationMilestoneStatus.expired)
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

    static func newDefaultRevocationMilestoneManager(_ store: any DefaultRevocationMilestoneStore, clock: any Kit.Clocks.Clock) -> DefaultRevocationMilestoneManager {
        return DefaultRevocationMilestoneManager(
            store: store,
            validator: defaultDefaultRevocationMilestoneValidator(),
            clock: clock,
            journal: []
        )
    }
}
