import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves capped substitution baselines through their life cycle and keeps a journal of what it did.
    final class CappedSubstitutionBaselineCoordinator {
        var store: any CappedSubstitutionBaselineStore
        var validator: CappedSubstitutionBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedSubstitutionBaselineEngine

        init(store: any CappedSubstitutionBaselineStore, validator: CappedSubstitutionBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedSubstitutionBaselineEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped substitution baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedSubstitutionBaselineStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped substitution baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedSubstitutionBaselineStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped substitution baseline \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newCappedSubstitutionBaselineCoordinator(_ store: any CappedSubstitutionBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedSubstitutionBaselineCoordinator {
        return CappedSubstitutionBaselineCoordinator(
            store: store,
            validator: defaultCappedSubstitutionBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedSubstitutionBaselineEngine(flags)
        )
    }
}
