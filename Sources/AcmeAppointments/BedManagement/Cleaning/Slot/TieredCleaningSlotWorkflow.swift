import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves tiered cleaning slots through their life cycle and keeps a journal of what it did.
    final class TieredCleaningSlotWorkflow {
        var store: any TieredCleaningSlotStore
        var validator: TieredCleaningSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredCleaningSlotStore, validator: TieredCleaningSlotValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered cleaning slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredCleaningSlotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered cleaning slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredCleaningSlotStatus.archived)
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

    static func newTieredCleaningSlotWorkflow(_ store: any TieredCleaningSlotStore, clock: any Kit.Clocks.Clock) -> TieredCleaningSlotWorkflow {
        return TieredCleaningSlotWorkflow(
            store: store,
            validator: defaultTieredCleaningSlotValidator(),
            clock: clock,
            journal: []
        )
    }
}
