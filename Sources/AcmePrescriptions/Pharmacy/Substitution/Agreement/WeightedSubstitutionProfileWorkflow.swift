import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted substitution profiles through their life cycle and keeps a journal of what it did.
    final class WeightedSubstitutionProfileManager {
        var store: any WeightedSubstitutionProfileStore
        var validator: WeightedSubstitutionProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedSubstitutionProfileEngine

        init(store: any WeightedSubstitutionProfileStore, validator: WeightedSubstitutionProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedSubstitutionProfileEngine) {
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
                throw Kit.Failure("weighted substitution profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedSubstitutionProfileStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted substitution profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedSubstitutionProfileStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted substitution profile \(code) not found")
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

    static func newWeightedSubstitutionProfileManager(_ store: any WeightedSubstitutionProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedSubstitutionProfileManager {
        return WeightedSubstitutionProfileManager(
            store: store,
            validator: defaultWeightedSubstitutionProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedSubstitutionProfileEngine(flags)
        )
    }
}
