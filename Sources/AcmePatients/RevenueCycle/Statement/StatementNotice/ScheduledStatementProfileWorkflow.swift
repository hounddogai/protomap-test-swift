import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves scheduled statement profiles through their life cycle and keeps a journal of what it did.
    final class ScheduledStatementProfileManager {
        var store: any ScheduledStatementProfileStore
        var validator: ScheduledStatementProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledStatementProfileEngine

        init(store: any ScheduledStatementProfileStore, validator: ScheduledStatementProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledStatementProfileEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled statement profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledStatementProfileStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled statement profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledStatementProfileStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled statement profile \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newScheduledStatementProfileManager(_ store: any ScheduledStatementProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledStatementProfileManager {
        return ScheduledStatementProfileManager(
            store: store,
            validator: defaultScheduledStatementProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledStatementProfileEngine(flags)
        )
    }
}
