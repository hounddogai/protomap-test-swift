import AcmePlatform
import Foundation

extension Referrals {
    /// Moves seasonal closure entries through their life cycle and keeps a journal of what it did.
    final class SeasonalClosureEntryDesk {
        var store: any SeasonalClosureEntryStore
        var validator: SeasonalClosureEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalClosureEntryEngine

        init(store: any SeasonalClosureEntryStore, validator: SeasonalClosureEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalClosureEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal closure entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalClosureEntryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal closure entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalClosureEntryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal closure entry \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newSeasonalClosureEntryDesk(_ store: any SeasonalClosureEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalClosureEntryDesk {
        return SeasonalClosureEntryDesk(
            store: store,
            validator: defaultSeasonalClosureEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalClosureEntryEngine(flags)
        )
    }
}
