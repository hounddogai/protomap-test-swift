import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning batches through their life cycle and keeps a journal of what it did.
    final class CleaningBatchCoordinator {
        var store: any CleaningBatchStore
        var validator: CleaningBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CleaningBatchEngine

        init(store: any CleaningBatchStore, validator: CleaningBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CleaningBatchEngine) {
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
                throw Kit.Failure("cleaning batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningBatchStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningBatchStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning batch \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCleaningBatchCoordinator(_ store: any CleaningBatchStore, clock: any Kit.Clocks.Clock) -> CleaningBatchCoordinator {
        return CleaningBatchCoordinator(
            store: store,
            validator: defaultCleaningBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultCleaningBatchEngine()
        )
    }
}
