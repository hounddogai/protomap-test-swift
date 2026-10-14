import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding preferences through their life cycle and keeps a journal of what it did.
    final class RoundingPreferenceDesk {
        var store: any RoundingPreferenceStore
        var validator: RoundingPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingPreferenceEngine

        init(store: any RoundingPreferenceStore, validator: RoundingPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingPreferenceEngine) {
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
                throw Kit.Failure("rounding preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingPreferenceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingPreferenceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding preference \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRoundingPreferenceDesk(_ store: any RoundingPreferenceStore, clock: any Kit.Clocks.Clock) -> RoundingPreferenceDesk {
        return RoundingPreferenceDesk(
            store: store,
            validator: defaultRoundingPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingPreferenceEngine()
        )
    }
}
