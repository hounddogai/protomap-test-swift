import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal read groups through their life cycle and keeps a journal of what it did.
    final class SeasonalReadGroupManager {
        var store: any SeasonalReadGroupStore
        var validator: SeasonalReadGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalReadGroupEngine

        init(store: any SeasonalReadGroupStore, validator: SeasonalReadGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalReadGroupEngine) {
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
                throw Kit.Failure("seasonal read group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalReadGroupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal read group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalReadGroupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal read group \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newSeasonalReadGroupManager(_ store: any SeasonalReadGroupStore, clock: any Kit.Clocks.Clock) -> SeasonalReadGroupManager {
        return SeasonalReadGroupManager(
            store: store,
            validator: defaultSeasonalReadGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalReadGroupEngine()
        )
    }
}
