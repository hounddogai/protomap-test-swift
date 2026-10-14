import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted substitution proposals through their life cycle and keeps a journal of what it did.
    final class WeightedSubstitutionProposalService {
        var store: any WeightedSubstitutionProposalStore
        var validator: WeightedSubstitutionProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedSubstitutionProposalEngine

        init(store: any WeightedSubstitutionProposalStore, validator: WeightedSubstitutionProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedSubstitutionProposalEngine) {
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
                throw Kit.Failure("weighted substitution proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedSubstitutionProposalStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted substitution proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedSubstitutionProposalStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted substitution proposal \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newWeightedSubstitutionProposalService(_ store: any WeightedSubstitutionProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedSubstitutionProposalService {
        return WeightedSubstitutionProposalService(
            store: store,
            validator: defaultWeightedSubstitutionProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedSubstitutionProposalEngine(flags)
        )
    }
}
