import AcmePlatform
import Foundation

extension Staffing {
    /// Moves adaptive shift baselines through their life cycle and keeps a journal of what it did.
    final class AdaptiveShiftBaselineDesk {
        var store: any AdaptiveShiftBaselineStore
        var validator: AdaptiveShiftBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveShiftBaselineEngine

        init(store: any AdaptiveShiftBaselineStore, validator: AdaptiveShiftBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveShiftBaselineEngine) {
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
                throw Kit.Failure("adaptive shift baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveShiftBaselineStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive shift baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveShiftBaselineStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive shift baseline \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newAdaptiveShiftBaselineDesk(_ store: any AdaptiveShiftBaselineStore, clock: any Kit.Clocks.Clock) -> AdaptiveShiftBaselineDesk {
        return AdaptiveShiftBaselineDesk(
            store: store,
            validator: defaultAdaptiveShiftBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveShiftBaselineEngine()
        )
    }
}
