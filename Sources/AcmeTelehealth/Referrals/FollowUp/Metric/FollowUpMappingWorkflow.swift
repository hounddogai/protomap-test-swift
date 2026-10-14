import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up mappings through their life cycle and keeps a journal of what it did.
    final class FollowUpMappingWorkflow {
        var store: any FollowUpMappingStore
        var validator: FollowUpMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpMappingStore, validator: FollowUpMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("follow up mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpMappingStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpMappingStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newFollowUpMappingWorkflow(_ store: any FollowUpMappingStore, clock: any Kit.Clocks.Clock) -> FollowUpMappingWorkflow {
        return FollowUpMappingWorkflow(
            store: store,
            validator: defaultFollowUpMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
