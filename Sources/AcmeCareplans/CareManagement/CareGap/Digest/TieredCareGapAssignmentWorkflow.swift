import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves tiered care gap assignments through their life cycle and keeps a journal of what it did.
    final class TieredCareGapAssignmentCoordinator {
        var store: any TieredCareGapAssignmentStore
        var validator: TieredCareGapAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredCareGapAssignmentStore, validator: TieredCareGapAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered care gap assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredCareGapAssignmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered care gap assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredCareGapAssignmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newTieredCareGapAssignmentCoordinator(_ store: any TieredCareGapAssignmentStore, clock: any Kit.Clocks.Clock) -> TieredCareGapAssignmentCoordinator {
        return TieredCareGapAssignmentCoordinator(
            store: store,
            validator: defaultTieredCareGapAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
