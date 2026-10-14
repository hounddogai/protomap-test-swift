import AcmePlatform
import Foundation

extension Labs {
    /// Moves default reference range variances through their life cycle and keeps a journal of what it did.
    final class DefaultReferenceRangeVarianceManager {
        var store: any DefaultReferenceRangeVarianceStore
        var validator: DefaultReferenceRangeVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultReferenceRangeVarianceEngine

        init(store: any DefaultReferenceRangeVarianceStore, validator: DefaultReferenceRangeVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultReferenceRangeVarianceEngine) {
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
                throw Kit.Failure("default reference range variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultReferenceRangeVarianceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default reference range variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultReferenceRangeVarianceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default reference range variance \(code) not found")
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

    static func newDefaultReferenceRangeVarianceManager(_ store: any DefaultReferenceRangeVarianceStore, clock: any Kit.Clocks.Clock) -> DefaultReferenceRangeVarianceManager {
        return DefaultReferenceRangeVarianceManager(
            store: store,
            validator: defaultDefaultReferenceRangeVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultReferenceRangeVarianceEngine()
        )
    }
}
