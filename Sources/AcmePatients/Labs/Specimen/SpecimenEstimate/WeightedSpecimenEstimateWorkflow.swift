import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted specimen estimates through their life cycle and keeps a journal of what it did.
    final class WeightedSpecimenEstimateService {
        var store: any WeightedSpecimenEstimateStore
        var validator: WeightedSpecimenEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedSpecimenEstimateEngine

        init(store: any WeightedSpecimenEstimateStore, validator: WeightedSpecimenEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedSpecimenEstimateEngine) {
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
                throw Kit.Failure("weighted specimen estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedSpecimenEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted specimen estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedSpecimenEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted specimen estimate \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newWeightedSpecimenEstimateService(_ store: any WeightedSpecimenEstimateStore, clock: any Kit.Clocks.Clock) -> WeightedSpecimenEstimateService {
        return WeightedSpecimenEstimateService(
            store: store,
            validator: defaultWeightedSpecimenEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedSpecimenEstimateEngine()
        )
    }
}
