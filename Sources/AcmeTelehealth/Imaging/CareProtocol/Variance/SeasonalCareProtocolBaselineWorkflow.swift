import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal care protocol baselines through their life cycle and keeps a journal of what it did.
    final class SeasonalCareProtocolBaselineWorkflow {
        var store: any SeasonalCareProtocolBaselineStore
        var validator: SeasonalCareProtocolBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalCareProtocolBaselineEngine

        init(store: any SeasonalCareProtocolBaselineStore, validator: SeasonalCareProtocolBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalCareProtocolBaselineEngine) {
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
                throw Kit.Failure("seasonal care protocol baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCareProtocolBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care protocol baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCareProtocolBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care protocol baseline \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newSeasonalCareProtocolBaselineWorkflow(_ store: any SeasonalCareProtocolBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalCareProtocolBaselineWorkflow {
        return SeasonalCareProtocolBaselineWorkflow(
            store: store,
            validator: defaultSeasonalCareProtocolBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalCareProtocolBaselineEngine(flags)
        )
    }
}
