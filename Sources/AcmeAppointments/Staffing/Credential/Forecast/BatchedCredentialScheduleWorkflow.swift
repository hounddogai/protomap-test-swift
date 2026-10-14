import AcmePlatform
import Foundation

extension Staffing {
    /// Moves batched credential schedules through their life cycle and keeps a journal of what it did.
    final class BatchedCredentialScheduleDesk {
        var store: any BatchedCredentialScheduleStore
        var validator: BatchedCredentialScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedCredentialScheduleEngine

        init(store: any BatchedCredentialScheduleStore, validator: BatchedCredentialScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedCredentialScheduleEngine) {
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
                throw Kit.Failure("batched credential schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedCredentialScheduleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched credential schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedCredentialScheduleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched credential schedule \(code) not found")
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

    static func newBatchedCredentialScheduleDesk(_ store: any BatchedCredentialScheduleStore, clock: any Kit.Clocks.Clock) -> BatchedCredentialScheduleDesk {
        return BatchedCredentialScheduleDesk(
            store: store,
            validator: defaultBatchedCredentialScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedCredentialScheduleEngine()
        )
    }
}
