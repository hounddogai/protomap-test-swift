import AcmePlatform
import Foundation

extension Consent {
    /// Moves legacy witness groups through their life cycle and keeps a journal of what it did.
    final class LegacyWitnessGroupDesk {
        var store: any LegacyWitnessGroupStore
        var validator: LegacyWitnessGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyWitnessGroupEngine

        init(store: any LegacyWitnessGroupStore, validator: LegacyWitnessGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyWitnessGroupEngine) {
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
                throw Kit.Failure("legacy witness group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyWitnessGroupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy witness group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyWitnessGroupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy witness group \(code) not found")
            }
            let result = engine.run(item)
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

    static func newLegacyWitnessGroupDesk(_ store: any LegacyWitnessGroupStore, clock: any Kit.Clocks.Clock) -> LegacyWitnessGroupDesk {
        return LegacyWitnessGroupDesk(
            store: store,
            validator: defaultLegacyWitnessGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyWitnessGroupEngine()
        )
    }
}
