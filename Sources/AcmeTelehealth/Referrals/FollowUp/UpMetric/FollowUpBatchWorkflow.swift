import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up batches through their life cycle and keeps a journal of what it did.
    final class FollowUpBatchManager {
        var store: any FollowUpBatchStore
        var validator: FollowUpBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpBatchEngine

        init(store: any FollowUpBatchStore, validator: FollowUpBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpBatchEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpBatchStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpBatchStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up batch \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newFollowUpBatchManager(_ store: any FollowUpBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FollowUpBatchManager {
        return FollowUpBatchManager(
            store: store,
            validator: defaultFollowUpBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpBatchEngine(flags)
        )
    }
}
