import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped cleaning scores through their life cycle and keeps a journal of what it did.
    final class CappedCleaningScoreManager {
        var store: any CappedCleaningScoreStore
        var validator: CappedCleaningScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedCleaningScoreStore, validator: CappedCleaningScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped cleaning score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCleaningScoreStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped cleaning score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCleaningScoreStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newCappedCleaningScoreManager(_ store: any CappedCleaningScoreStore, clock: any Kit.Clocks.Clock) -> CappedCleaningScoreManager {
        return CappedCleaningScoreManager(
            store: store,
            validator: defaultCappedCleaningScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
