import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves capped care gap batches through their life cycle and keeps a journal of what it did.
    final class CappedCareGapBatchCoordinator {
        var store: any CappedCareGapBatchStore
        var validator: CappedCareGapBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedCareGapBatchEngine

        init(store: any CappedCareGapBatchStore, validator: CappedCareGapBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedCareGapBatchEngine) {
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
                throw Kit.Failure("capped care gap batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCareGapBatchStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care gap batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCareGapBatchStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care gap batch \(code) not found")
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

    static func newCappedCareGapBatchCoordinator(_ store: any CappedCareGapBatchStore, clock: any Kit.Clocks.Clock) -> CappedCareGapBatchCoordinator {
        return CappedCareGapBatchCoordinator(
            store: store,
            validator: defaultCappedCareGapBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedCareGapBatchEngine()
        )
    }
}
