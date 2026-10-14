import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up rules through their life cycle and keeps a journal of what it did.
    final class FollowUpRuleCoordinator {
        var store: any FollowUpRuleStore
        var validator: FollowUpRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpRuleEngine

        init(store: any FollowUpRuleStore, validator: FollowUpRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpRuleEngine) {
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
                throw Kit.Failure("follow up rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpRuleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpRuleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up rule \(code) not found")
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

    static func newFollowUpRuleCoordinator(_ store: any FollowUpRuleStore, clock: any Kit.Clocks.Clock) -> FollowUpRuleCoordinator {
        return FollowUpRuleCoordinator(
            store: store,
            validator: defaultFollowUpRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpRuleEngine()
        )
    }
}
