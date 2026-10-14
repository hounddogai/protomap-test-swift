import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves scheduled recall profiles through their life cycle and keeps a journal of what it did.
    final class ScheduledRecallProfileWorkflow {
        var store: any ScheduledRecallProfileStore
        var validator: ScheduledRecallProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledRecallProfileEngine

        init(store: any ScheduledRecallProfileStore, validator: ScheduledRecallProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledRecallProfileEngine) {
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
                throw Kit.Failure("scheduled recall profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledRecallProfileStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled recall profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledRecallProfileStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled recall profile \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newScheduledRecallProfileWorkflow(_ store: any ScheduledRecallProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledRecallProfileWorkflow {
        return ScheduledRecallProfileWorkflow(
            store: store,
            validator: defaultScheduledRecallProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledRecallProfileEngine(flags)
        )
    }
}
