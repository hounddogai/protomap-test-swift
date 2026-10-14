import AcmePlatform
import Foundation

extension Referrals {
    /// Moves global closure claims through their life cycle and keeps a journal of what it did.
    final class GlobalClosureClaimCoordinator {
        var store: any GlobalClosureClaimStore
        var validator: GlobalClosureClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalClosureClaimEngine

        init(store: any GlobalClosureClaimStore, validator: GlobalClosureClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalClosureClaimEngine) {
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
                throw Kit.Failure("global closure claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalClosureClaimStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global closure claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalClosureClaimStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global closure claim \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newGlobalClosureClaimCoordinator(_ store: any GlobalClosureClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalClosureClaimCoordinator {
        return GlobalClosureClaimCoordinator(
            store: store,
            validator: defaultGlobalClosureClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalClosureClaimEngine(flags)
        )
    }
}
