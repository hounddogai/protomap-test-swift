import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves scheduled task reviews through their life cycle and keeps a journal of what it did.
    final class ScheduledTaskReviewManager {
        var store: any ScheduledTaskReviewStore
        var validator: ScheduledTaskReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledTaskReviewEngine

        init(store: any ScheduledTaskReviewStore, validator: ScheduledTaskReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledTaskReviewEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled task review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledTaskReviewStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled task review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledTaskReviewStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled task review \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newScheduledTaskReviewManager(_ store: any ScheduledTaskReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledTaskReviewManager {
        return ScheduledTaskReviewManager(
            store: store,
            validator: defaultScheduledTaskReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledTaskReviewEngine(flags)
        )
    }
}
