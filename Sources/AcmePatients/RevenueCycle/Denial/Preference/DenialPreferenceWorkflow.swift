import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial preferences through their life cycle and keeps a journal of what it did.
    final class DenialPreferenceWorkflow {
        var store: any DenialPreferenceStore
        var validator: DenialPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialPreferenceEngine

        init(store: any DenialPreferenceStore, validator: DenialPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialPreferenceEngine) {
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
                throw Kit.Failure("denial preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialPreferenceStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialPreferenceStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial preference \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newDenialPreferenceWorkflow(_ store: any DenialPreferenceStore, clock: any Kit.Clocks.Clock) -> DenialPreferenceWorkflow {
        return DenialPreferenceWorkflow(
            store: store,
            validator: defaultDenialPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialPreferenceEngine()
        )
    }
}
