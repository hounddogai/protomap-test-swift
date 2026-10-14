import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted formulary estimates through their life cycle and keeps a journal of what it did.
    final class WeightedFormularyEstimateDesk {
        var store: any WeightedFormularyEstimateStore
        var validator: WeightedFormularyEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedFormularyEstimateEngine

        init(store: any WeightedFormularyEstimateStore, validator: WeightedFormularyEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedFormularyEstimateEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted formulary estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedFormularyEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted formulary estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedFormularyEstimateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted formulary estimate \(code) not found")
            }
            let result = engine.price(item)
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

    static func newWeightedFormularyEstimateDesk(_ store: any WeightedFormularyEstimateStore, clock: any Kit.Clocks.Clock) -> WeightedFormularyEstimateDesk {
        return WeightedFormularyEstimateDesk(
            store: store,
            validator: defaultWeightedFormularyEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedFormularyEstimateEngine()
        )
    }
}
