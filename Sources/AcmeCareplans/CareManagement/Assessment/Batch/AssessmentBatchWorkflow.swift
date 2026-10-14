import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves assessment batches through their life cycle and keeps a journal of what it did.
    final class AssessmentBatchService {
        var store: any AssessmentBatchStore
        var validator: AssessmentBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AssessmentBatchEngine

        init(store: any AssessmentBatchStore, validator: AssessmentBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AssessmentBatchEngine) {
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
                throw Kit.Failure("assessment batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AssessmentBatchStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AssessmentBatchStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("assessment batch \(code) not found")
            }
            let result = engine.price(item)
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

    static func newAssessmentBatchService(_ store: any AssessmentBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AssessmentBatchService {
        return AssessmentBatchService(
            store: store,
            validator: defaultAssessmentBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultAssessmentBatchEngine(flags)
        )
    }
}
