import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution scores through their life cycle and keeps a journal of what it did.
    final class SubstitutionScoreCoordinator {
        var store: any SubstitutionScoreStore
        var validator: SubstitutionScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionScoreEngine

        init(store: any SubstitutionScoreStore, validator: SubstitutionScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionScoreEngine) {
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
                throw Kit.Failure("substitution score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionScoreStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionScoreStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution score \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newSubstitutionScoreCoordinator(_ store: any SubstitutionScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SubstitutionScoreCoordinator {
        return SubstitutionScoreCoordinator(
            store: store,
            validator: defaultSubstitutionScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionScoreEngine(flags)
        )
    }
}
