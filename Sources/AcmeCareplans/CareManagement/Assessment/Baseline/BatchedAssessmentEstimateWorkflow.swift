import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves batched assessment estimates through their life cycle and keeps a journal of what it did.
    final class BatchedAssessmentEstimateCoordinator {
        var store: any BatchedAssessmentEstimateStore
        var validator: BatchedAssessmentEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BatchedAssessmentEstimateStore, validator: BatchedAssessmentEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched assessment estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedAssessmentEstimateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched assessment estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedAssessmentEstimateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newBatchedAssessmentEstimateCoordinator(_ store: any BatchedAssessmentEstimateStore, clock: any Kit.Clocks.Clock) -> BatchedAssessmentEstimateCoordinator {
        return BatchedAssessmentEstimateCoordinator(
            store: store,
            validator: defaultBatchedAssessmentEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
