import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves pending cleaning windows through their life cycle and keeps a journal of what it did.
    final class PendingCleaningWindowWorkflow {
        var store: any PendingCleaningWindowStore
        var validator: PendingCleaningWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingCleaningWindowEngine

        init(store: any PendingCleaningWindowStore, validator: PendingCleaningWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingCleaningWindowEngine) {
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
                throw Kit.Failure("pending cleaning window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCleaningWindowStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending cleaning window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCleaningWindowStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending cleaning window \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPendingCleaningWindowWorkflow(_ store: any PendingCleaningWindowStore, clock: any Kit.Clocks.Clock) -> PendingCleaningWindowWorkflow {
        return PendingCleaningWindowWorkflow(
            store: store,
            validator: defaultPendingCleaningWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingCleaningWindowEngine()
        )
    }
}
