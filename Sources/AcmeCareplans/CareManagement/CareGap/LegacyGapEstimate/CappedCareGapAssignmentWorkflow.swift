import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves capped care gap assignments through their life cycle and keeps a journal of what it did.
    final class CappedCareGapAssignmentDesk {
        var store: any CappedCareGapAssignmentStore
        var validator: CappedCareGapAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedCareGapAssignmentEngine

        init(store: any CappedCareGapAssignmentStore, validator: CappedCareGapAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedCareGapAssignmentEngine) {
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
                throw Kit.Failure("capped care gap assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCareGapAssignmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care gap assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCareGapAssignmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care gap assignment \(code) not found")
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

    static func newCappedCareGapAssignmentDesk(_ store: any CappedCareGapAssignmentStore, clock: any Kit.Clocks.Clock) -> CappedCareGapAssignmentDesk {
        return CappedCareGapAssignmentDesk(
            store: store,
            validator: defaultCappedCareGapAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedCareGapAssignmentEngine()
        )
    }
}
