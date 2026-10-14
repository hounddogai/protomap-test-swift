import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted substitution digests through their life cycle and keeps a journal of what it did.
    final class WeightedSubstitutionDigestDesk {
        var store: any WeightedSubstitutionDigestStore
        var validator: WeightedSubstitutionDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedSubstitutionDigestEngine

        init(store: any WeightedSubstitutionDigestStore, validator: WeightedSubstitutionDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedSubstitutionDigestEngine) {
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
                throw Kit.Failure("weighted substitution digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedSubstitutionDigestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted substitution digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedSubstitutionDigestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted substitution digest \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newWeightedSubstitutionDigestDesk(_ store: any WeightedSubstitutionDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedSubstitutionDigestDesk {
        return WeightedSubstitutionDigestDesk(
            store: store,
            validator: defaultWeightedSubstitutionDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedSubstitutionDigestEngine(flags)
        )
    }
}
