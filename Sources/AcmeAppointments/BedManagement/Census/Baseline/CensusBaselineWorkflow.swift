import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census baselines through their life cycle and keeps a journal of what it did.
    final class CensusBaselineManager {
        var store: any CensusBaselineStore
        var validator: CensusBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CensusBaselineEngine

        init(store: any CensusBaselineStore, validator: CensusBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CensusBaselineEngine) {
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
                throw Kit.Failure("census baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusBaselineStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusBaselineStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("census baseline \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCensusBaselineManager(_ store: any CensusBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CensusBaselineManager {
        return CensusBaselineManager(
            store: store,
            validator: defaultCensusBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultCensusBaselineEngine(flags)
        )
    }
}
