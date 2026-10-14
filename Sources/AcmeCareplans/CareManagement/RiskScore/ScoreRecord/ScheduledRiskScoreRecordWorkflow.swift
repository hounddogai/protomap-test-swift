import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves scheduled risk score records through their life cycle and keeps a journal of what it did.
    final class ScheduledRiskScoreRecordCoordinator {
        var store: any ScheduledRiskScoreRecordStore
        var validator: ScheduledRiskScoreRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledRiskScoreRecordEngine

        init(store: any ScheduledRiskScoreRecordStore, validator: ScheduledRiskScoreRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledRiskScoreRecordEngine) {
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
                throw Kit.Failure("scheduled risk score record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledRiskScoreRecordStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled risk score record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledRiskScoreRecordStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled risk score record \(code) not found")
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

    static func newScheduledRiskScoreRecordCoordinator(_ store: any ScheduledRiskScoreRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledRiskScoreRecordCoordinator {
        return ScheduledRiskScoreRecordCoordinator(
            store: store,
            validator: defaultScheduledRiskScoreRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledRiskScoreRecordEngine(flags)
        )
    }
}
