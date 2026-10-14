import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient risk score preferences through their life cycle and keeps a journal of what it did.
    final class LenientRiskScorePreferenceDesk {
        var store: any LenientRiskScorePreferenceStore
        var validator: LenientRiskScorePreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientRiskScorePreferenceEngine

        init(store: any LenientRiskScorePreferenceStore, validator: LenientRiskScorePreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientRiskScorePreferenceEngine) {
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
                throw Kit.Failure("lenient risk score preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRiskScorePreferenceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient risk score preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRiskScorePreferenceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient risk score preference \(code) not found")
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

    static func newLenientRiskScorePreferenceDesk(_ store: any LenientRiskScorePreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientRiskScorePreferenceDesk {
        return LenientRiskScorePreferenceDesk(
            store: store,
            validator: defaultLenientRiskScorePreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientRiskScorePreferenceEngine(flags)
        )
    }
}
