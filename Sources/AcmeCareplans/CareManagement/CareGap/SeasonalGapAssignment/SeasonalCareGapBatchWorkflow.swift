import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves seasonal care gap batches through their life cycle and keeps a journal of what it did.
    final class SeasonalCareGapBatchDesk {
        var store: any SeasonalCareGapBatchStore
        var validator: SeasonalCareGapBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalCareGapBatchStore, validator: SeasonalCareGapBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCareGapBatchStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCareGapBatchStatus.failed)
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

    static func newSeasonalCareGapBatchDesk(_ store: any SeasonalCareGapBatchStore, clock: any Kit.Clocks.Clock) -> SeasonalCareGapBatchDesk {
        return SeasonalCareGapBatchDesk(
            store: store,
            validator: defaultSeasonalCareGapBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
