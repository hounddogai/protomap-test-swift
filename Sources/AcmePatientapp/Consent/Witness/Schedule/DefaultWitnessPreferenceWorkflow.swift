import AcmePlatform
import Foundation

extension Consent {
    /// Moves default witness preferences through their life cycle and keeps a journal of what it did.
    final class DefaultWitnessPreferenceService {
        var store: any DefaultWitnessPreferenceStore
        var validator: DefaultWitnessPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultWitnessPreferenceEngine

        init(store: any DefaultWitnessPreferenceStore, validator: DefaultWitnessPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultWitnessPreferenceEngine) {
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
                throw Kit.Failure("default witness preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultWitnessPreferenceStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default witness preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultWitnessPreferenceStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default witness preference \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDefaultWitnessPreferenceService(_ store: any DefaultWitnessPreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultWitnessPreferenceService {
        return DefaultWitnessPreferenceService(
            store: store,
            validator: defaultDefaultWitnessPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultWitnessPreferenceEngine(flags)
        )
    }
}
