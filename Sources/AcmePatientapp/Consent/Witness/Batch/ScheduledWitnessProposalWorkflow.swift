import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled witness proposals through their life cycle and keeps a journal of what it did.
    final class ScheduledWitnessProposalManager {
        var store: any ScheduledWitnessProposalStore
        var validator: ScheduledWitnessProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ScheduledWitnessProposalStore, validator: ScheduledWitnessProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("scheduled witness proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledWitnessProposalStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled witness proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledWitnessProposalStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newScheduledWitnessProposalManager(_ store: any ScheduledWitnessProposalStore, clock: any Kit.Clocks.Clock) -> ScheduledWitnessProposalManager {
        return ScheduledWitnessProposalManager(
            store: store,
            validator: defaultScheduledWitnessProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
