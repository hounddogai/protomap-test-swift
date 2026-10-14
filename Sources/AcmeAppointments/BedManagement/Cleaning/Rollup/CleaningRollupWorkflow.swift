import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning rollups through their life cycle and keeps a journal of what it did.
    final class CleaningRollupDesk {
        var store: any CleaningRollupStore
        var validator: CleaningRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CleaningRollupStore, validator: CleaningRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("cleaning rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningRollupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningRollupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newCleaningRollupDesk(_ store: any CleaningRollupStore, clock: any Kit.Clocks.Clock) -> CleaningRollupDesk {
        return CleaningRollupDesk(
            store: store,
            validator: defaultCleaningRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
