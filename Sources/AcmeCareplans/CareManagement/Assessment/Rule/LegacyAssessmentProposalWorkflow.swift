import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy assessment proposals through their life cycle and keeps a journal of what it did.
    final class LegacyAssessmentProposalService {
        var store: any LegacyAssessmentProposalStore
        var validator: LegacyAssessmentProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyAssessmentProposalEngine

        init(store: any LegacyAssessmentProposalStore, validator: LegacyAssessmentProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyAssessmentProposalEngine) {
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
                throw Kit.Failure("legacy assessment proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyAssessmentProposalStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy assessment proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyAssessmentProposalStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy assessment proposal \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newLegacyAssessmentProposalService(_ store: any LegacyAssessmentProposalStore, clock: any Kit.Clocks.Clock) -> LegacyAssessmentProposalService {
        return LegacyAssessmentProposalService(
            store: store,
            validator: defaultLegacyAssessmentProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyAssessmentProposalEngine()
        )
    }
}
