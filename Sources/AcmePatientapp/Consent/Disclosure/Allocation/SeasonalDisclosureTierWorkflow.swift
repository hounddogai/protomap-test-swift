import AcmePlatform
import Foundation

extension Consent {
    /// Moves seasonal disclosure tiers through their life cycle and keeps a journal of what it did.
    final class SeasonalDisclosureTierCoordinator {
        var store: any SeasonalDisclosureTierStore
        var validator: SeasonalDisclosureTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalDisclosureTierEngine

        init(store: any SeasonalDisclosureTierStore, validator: SeasonalDisclosureTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalDisclosureTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal disclosure tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalDisclosureTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal disclosure tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalDisclosureTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal disclosure tier \(code) not found")
            }
            let result = engine.run(item)
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

    static func newSeasonalDisclosureTierCoordinator(_ store: any SeasonalDisclosureTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalDisclosureTierCoordinator {
        return SeasonalDisclosureTierCoordinator(
            store: store,
            validator: defaultSeasonalDisclosureTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalDisclosureTierEngine(flags)
        )
    }
}
