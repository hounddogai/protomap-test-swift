import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal read exceptions through their life cycle and keeps a journal of what it did.
    final class SeasonalReadExceptionManager {
        var store: any SeasonalReadExceptionStore
        var validator: SeasonalReadExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalReadExceptionEngine

        init(store: any SeasonalReadExceptionStore, validator: SeasonalReadExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalReadExceptionEngine) {
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
                throw Kit.Failure("seasonal read exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalReadExceptionStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal read exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalReadExceptionStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal read exception \(code) not found")
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

    static func newSeasonalReadExceptionManager(_ store: any SeasonalReadExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalReadExceptionManager {
        return SeasonalReadExceptionManager(
            store: store,
            validator: defaultSeasonalReadExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalReadExceptionEngine(flags)
        )
    }
}
