import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves strict assessment exceptions through their life cycle and keeps a journal of what it did.
    final class StrictAssessmentExceptionService {
        var store: any StrictAssessmentExceptionStore
        var validator: StrictAssessmentExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictAssessmentExceptionEngine

        init(store: any StrictAssessmentExceptionStore, validator: StrictAssessmentExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictAssessmentExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict assessment exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictAssessmentExceptionStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict assessment exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictAssessmentExceptionStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict assessment exception \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newStrictAssessmentExceptionService(_ store: any StrictAssessmentExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictAssessmentExceptionService {
        return StrictAssessmentExceptionService(
            store: store,
            validator: defaultStrictAssessmentExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictAssessmentExceptionEngine(flags)
        )
    }
}
