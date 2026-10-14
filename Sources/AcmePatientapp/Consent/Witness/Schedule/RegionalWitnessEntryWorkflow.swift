import AcmePlatform
import Foundation

extension Consent {
    /// Moves regional witness entries through their life cycle and keeps a journal of what it did.
    final class RegionalWitnessEntryCoordinator {
        var store: any RegionalWitnessEntryStore
        var validator: RegionalWitnessEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalWitnessEntryEngine

        init(store: any RegionalWitnessEntryStore, validator: RegionalWitnessEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalWitnessEntryEngine) {
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
                throw Kit.Failure("regional witness entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalWitnessEntryStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional witness entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalWitnessEntryStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional witness entry \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRegionalWitnessEntryCoordinator(_ store: any RegionalWitnessEntryStore, clock: any Kit.Clocks.Clock) -> RegionalWitnessEntryCoordinator {
        return RegionalWitnessEntryCoordinator(
            store: store,
            validator: defaultRegionalWitnessEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalWitnessEntryEngine()
        )
    }
}
