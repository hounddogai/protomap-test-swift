import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves primary substitution tiers through their life cycle and keeps a journal of what it did.
    final class PrimarySubstitutionTierWorkflow {
        var store: any PrimarySubstitutionTierStore
        var validator: PrimarySubstitutionTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimarySubstitutionTierEngine

        init(store: any PrimarySubstitutionTierStore, validator: PrimarySubstitutionTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimarySubstitutionTierEngine) {
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
                throw Kit.Failure("primary substitution tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimarySubstitutionTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary substitution tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimarySubstitutionTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary substitution tier \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newPrimarySubstitutionTierWorkflow(_ store: any PrimarySubstitutionTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimarySubstitutionTierWorkflow {
        return PrimarySubstitutionTierWorkflow(
            store: store,
            validator: defaultPrimarySubstitutionTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimarySubstitutionTierEngine(flags)
        )
    }
}
