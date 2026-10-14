import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled follow up cycles through their life cycle and keeps a journal of what it did.
    final class ScheduledFollowUpCycleService {
        var store: any ScheduledFollowUpCycleStore
        var validator: ScheduledFollowUpCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledFollowUpCycleEngine

        init(store: any ScheduledFollowUpCycleStore, validator: ScheduledFollowUpCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledFollowUpCycleEngine) {
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
                throw Kit.Failure("scheduled follow up cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledFollowUpCycleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled follow up cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledFollowUpCycleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled follow up cycle \(code) not found")
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

    static func newScheduledFollowUpCycleService(_ store: any ScheduledFollowUpCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledFollowUpCycleService {
        return ScheduledFollowUpCycleService(
            store: store,
            validator: defaultScheduledFollowUpCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledFollowUpCycleEngine(flags)
        )
    }
}
