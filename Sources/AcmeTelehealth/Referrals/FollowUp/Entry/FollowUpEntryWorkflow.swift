import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up entries through their life cycle and keeps a journal of what it did.
    final class FollowUpEntryManager {
        var store: any FollowUpEntryStore
        var validator: FollowUpEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpEntryEngine

        init(store: any FollowUpEntryStore, validator: FollowUpEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up entry \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newFollowUpEntryManager(_ store: any FollowUpEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FollowUpEntryManager {
        return FollowUpEntryManager(
            store: store,
            validator: defaultFollowUpEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpEntryEngine(flags)
        )
    }
}
