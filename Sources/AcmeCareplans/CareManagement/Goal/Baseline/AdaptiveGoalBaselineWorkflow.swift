import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves adaptive goal baselines through their life cycle and keeps a journal of what it did.
    final class AdaptiveGoalBaselineManager {
        var store: any AdaptiveGoalBaselineStore
        var validator: AdaptiveGoalBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveGoalBaselineEngine

        init(store: any AdaptiveGoalBaselineStore, validator: AdaptiveGoalBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveGoalBaselineEngine) {
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
                throw Kit.Failure("adaptive goal baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveGoalBaselineStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive goal baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveGoalBaselineStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive goal baseline \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newAdaptiveGoalBaselineManager(_ store: any AdaptiveGoalBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveGoalBaselineManager {
        return AdaptiveGoalBaselineManager(
            store: store,
            validator: defaultAdaptiveGoalBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveGoalBaselineEngine(flags)
        )
    }
}
