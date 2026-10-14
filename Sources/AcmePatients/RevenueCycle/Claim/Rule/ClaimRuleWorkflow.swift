import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim rules through their life cycle and keeps a journal of what it did.
    final class ClaimRuleCoordinator {
        var store: any ClaimRuleStore
        var validator: ClaimRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimRuleEngine

        init(store: any ClaimRuleStore, validator: ClaimRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimRuleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimRuleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimRuleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim rule \(code) not found")
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

    static func newClaimRuleCoordinator(_ store: any ClaimRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClaimRuleCoordinator {
        return ClaimRuleCoordinator(
            store: store,
            validator: defaultClaimRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimRuleEngine(flags)
        )
    }
}
