import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range variances through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeVarianceManager {
        var store: any ReferenceRangeVarianceStore
        var validator: ReferenceRangeVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ReferenceRangeVarianceEngine

        init(store: any ReferenceRangeVarianceStore, validator: ReferenceRangeVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ReferenceRangeVarianceEngine) {
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
                throw Kit.Failure("reference range variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeVarianceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeVarianceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range variance \(code) not found")
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

    static func newReferenceRangeVarianceManager(_ store: any ReferenceRangeVarianceStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeVarianceManager {
        return ReferenceRangeVarianceManager(
            store: store,
            validator: defaultReferenceRangeVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultReferenceRangeVarianceEngine()
        )
    }
}
