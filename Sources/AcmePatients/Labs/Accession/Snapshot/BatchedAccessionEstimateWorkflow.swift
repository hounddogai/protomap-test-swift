import AcmePlatform
import Foundation

extension Labs {
    /// Moves batched accession estimates through their life cycle and keeps a journal of what it did.
    final class BatchedAccessionEstimateService {
        var store: any BatchedAccessionEstimateStore
        var validator: BatchedAccessionEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedAccessionEstimateEngine

        init(store: any BatchedAccessionEstimateStore, validator: BatchedAccessionEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedAccessionEstimateEngine) {
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
                throw Kit.Failure("batched accession estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedAccessionEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched accession estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedAccessionEstimateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched accession estimate \(code) not found")
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

    static func newBatchedAccessionEstimateService(_ store: any BatchedAccessionEstimateStore, clock: any Kit.Clocks.Clock) -> BatchedAccessionEstimateService {
        return BatchedAccessionEstimateService(
            store: store,
            validator: defaultBatchedAccessionEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedAccessionEstimateEngine()
        )
    }
}
