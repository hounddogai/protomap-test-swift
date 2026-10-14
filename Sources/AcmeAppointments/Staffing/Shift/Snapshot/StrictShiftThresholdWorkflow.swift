import AcmePlatform
import Foundation

extension Staffing {
    /// Moves strict shift thresholds through their life cycle and keeps a journal of what it did.
    final class StrictShiftThresholdCoordinator {
        var store: any StrictShiftThresholdStore
        var validator: StrictShiftThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictShiftThresholdEngine

        init(store: any StrictShiftThresholdStore, validator: StrictShiftThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictShiftThresholdEngine) {
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
                throw Kit.Failure("strict shift threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictShiftThresholdStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict shift threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictShiftThresholdStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict shift threshold \(code) not found")
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

    static func newStrictShiftThresholdCoordinator(_ store: any StrictShiftThresholdStore, clock: any Kit.Clocks.Clock) -> StrictShiftThresholdCoordinator {
        return StrictShiftThresholdCoordinator(
            store: store,
            validator: defaultStrictShiftThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictShiftThresholdEngine()
        )
    }
}
