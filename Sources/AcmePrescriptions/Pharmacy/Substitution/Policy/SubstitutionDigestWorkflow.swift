import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution digests through their life cycle and keeps a journal of what it did.
    final class SubstitutionDigestCoordinator {
        var store: any SubstitutionDigestStore
        var validator: SubstitutionDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionDigestEngine

        init(store: any SubstitutionDigestStore, validator: SubstitutionDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionDigestEngine) {
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
                throw Kit.Failure("substitution digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionDigestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionDigestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution digest \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newSubstitutionDigestCoordinator(_ store: any SubstitutionDigestStore, clock: any Kit.Clocks.Clock) -> SubstitutionDigestCoordinator {
        return SubstitutionDigestCoordinator(
            store: store,
            validator: defaultSubstitutionDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionDigestEngine()
        )
    }
}
