import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled follow up groups through their life cycle and keeps a journal of what it did.
    final class ScheduledFollowUpGroupService {
        var store: any ScheduledFollowUpGroupStore
        var validator: ScheduledFollowUpGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledFollowUpGroupEngine

        init(store: any ScheduledFollowUpGroupStore, validator: ScheduledFollowUpGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledFollowUpGroupEngine) {
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
                throw Kit.Failure("scheduled follow up group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledFollowUpGroupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled follow up group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledFollowUpGroupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled follow up group \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newScheduledFollowUpGroupService(_ store: any ScheduledFollowUpGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledFollowUpGroupService {
        return ScheduledFollowUpGroupService(
            store: store,
            validator: defaultScheduledFollowUpGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledFollowUpGroupEngine(flags)
        )
    }
}
