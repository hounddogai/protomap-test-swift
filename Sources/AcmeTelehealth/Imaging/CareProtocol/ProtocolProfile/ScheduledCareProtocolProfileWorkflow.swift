import AcmePlatform
import Foundation

extension Imaging {
    /// Moves scheduled care protocol profiles through their life cycle and keeps a journal of what it did.
    final class ScheduledCareProtocolProfileDesk {
        var store: any ScheduledCareProtocolProfileStore
        var validator: ScheduledCareProtocolProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledCareProtocolProfileEngine

        init(store: any ScheduledCareProtocolProfileStore, validator: ScheduledCareProtocolProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledCareProtocolProfileEngine) {
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
                throw Kit.Failure("scheduled care protocol profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCareProtocolProfileStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCareProtocolProfileStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol profile \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newScheduledCareProtocolProfileDesk(_ store: any ScheduledCareProtocolProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledCareProtocolProfileDesk {
        return ScheduledCareProtocolProfileDesk(
            store: store,
            validator: defaultScheduledCareProtocolProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledCareProtocolProfileEngine(flags)
        )
    }
}
