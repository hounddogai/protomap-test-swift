import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment scores through their life cycle and keeps a journal of what it did.
    final class AssessmentScoreDesk {
        var store: any AssessmentScoreStore
        var validator: AssessmentScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AssessmentScoreEngine

        init(store: any AssessmentScoreStore, validator: AssessmentScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AssessmentScoreEngine) {
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
                throw Kit.Failure("assessment score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentScoreStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentScoreStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment score \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newAssessmentScoreDesk(_ store: any AssessmentScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AssessmentScoreDesk {
        return AssessmentScoreDesk(
            store: store,
            validator: defaultAssessmentScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultAssessmentScoreEngine(flags)
        )
    }
}
