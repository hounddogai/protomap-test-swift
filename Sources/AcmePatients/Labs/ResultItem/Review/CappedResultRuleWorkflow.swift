import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped result rules through their life cycle and keeps a journal of what it did.
    final class CappedResultRuleCoordinator {
        var store: any CappedResultRuleStore
        var validator: CappedResultRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedResultRuleEngine

        init(store: any CappedResultRuleStore, validator: CappedResultRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedResultRuleEngine) {
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
                throw Kit.Failure("capped result rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedResultRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped result rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedResultRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped result rule \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCappedResultRuleCoordinator(_ store: any CappedResultRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedResultRuleCoordinator {
        return CappedResultRuleCoordinator(
            store: store,
            validator: defaultCappedResultRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedResultRuleEngine(flags)
        )
    }
}
