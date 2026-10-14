import AcmePlatform
import Foundation

extension Labs {
    /// Moves strict result claims through their life cycle and keeps a journal of what it did.
    final class StrictResultClaimService {
        var store: any StrictResultClaimStore
        var validator: StrictResultClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictResultClaimEngine

        init(store: any StrictResultClaimStore, validator: StrictResultClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictResultClaimEngine) {
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
                throw Kit.Failure("strict result claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictResultClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict result claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictResultClaimStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict result claim \(code) not found")
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

    static func newStrictResultClaimService(_ store: any StrictResultClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictResultClaimService {
        return StrictResultClaimService(
            store: store,
            validator: defaultStrictResultClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictResultClaimEngine(flags)
        )
    }
}
