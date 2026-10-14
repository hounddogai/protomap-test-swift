import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves seasonal care gap assignments through their life cycle and keeps a journal of what it did.
    final class SeasonalCareGapAssignmentWorkflow {
        var store: any SeasonalCareGapAssignmentStore
        var validator: SeasonalCareGapAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalCareGapAssignmentStore, validator: SeasonalCareGapAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCareGapAssignmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCareGapAssignmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newSeasonalCareGapAssignmentWorkflow(_ store: any SeasonalCareGapAssignmentStore, clock: any Kit.Clocks.Clock) -> SeasonalCareGapAssignmentWorkflow {
        return SeasonalCareGapAssignmentWorkflow(
            store: store,
            validator: defaultSeasonalCareGapAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
