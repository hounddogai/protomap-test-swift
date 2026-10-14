import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted reference range estimates through their life cycle and keeps a journal of what it did.
    final class WeightedReferenceRangeEstimateService {
        var store: any WeightedReferenceRangeEstimateStore
        var validator: WeightedReferenceRangeEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedReferenceRangeEstimateEngine

        init(store: any WeightedReferenceRangeEstimateStore, validator: WeightedReferenceRangeEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedReferenceRangeEstimateEngine) {
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
                throw Kit.Failure("weighted reference range estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedReferenceRangeEstimateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted reference range estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedReferenceRangeEstimateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted reference range estimate \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newWeightedReferenceRangeEstimateService(_ store: any WeightedReferenceRangeEstimateStore, clock: any Kit.Clocks.Clock) -> WeightedReferenceRangeEstimateService {
        return WeightedReferenceRangeEstimateService(
            store: store,
            validator: defaultWeightedReferenceRangeEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedReferenceRangeEstimateEngine()
        )
    }
}
