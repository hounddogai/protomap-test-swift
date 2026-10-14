import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment agreements through their life cycle and keeps a journal of what it did.
    final class AssessmentAgreementCoordinator {
        var store: any AssessmentAgreementStore
        var validator: AssessmentAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AssessmentAgreementEngine

        init(store: any AssessmentAgreementStore, validator: AssessmentAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AssessmentAgreementEngine) {
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
                throw Kit.Failure("assessment agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment agreement \(code) not found")
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

    static func newAssessmentAgreementCoordinator(_ store: any AssessmentAgreementStore, clock: any Kit.Clocks.Clock) -> AssessmentAgreementCoordinator {
        return AssessmentAgreementCoordinator(
            store: store,
            validator: defaultAssessmentAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultAssessmentAgreementEngine()
        )
    }
}
