import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap adjustments through their life cycle and keeps a journal of what it did.
    final class CareGapAdjustmentCoordinator {
        var store: any CareGapAdjustmentStore
        var validator: CareGapAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareGapAdjustmentStore, validator: CareGapAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapAdjustmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapAdjustmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCareGapAdjustmentCoordinator(_ store: any CareGapAdjustmentStore, clock: any Kit.Clocks.Clock) -> CareGapAdjustmentCoordinator {
        return CareGapAdjustmentCoordinator(
            store: store,
            validator: defaultCareGapAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
