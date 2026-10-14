import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional study rules through their life cycle and keeps a journal of what it did.
    final class RegionalStudyRuleManager {
        var store: any RegionalStudyRuleStore
        var validator: RegionalStudyRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalStudyRuleEngine

        init(store: any RegionalStudyRuleStore, validator: RegionalStudyRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalStudyRuleEngine) {
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
                throw Kit.Failure("regional study rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalStudyRuleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional study rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalStudyRuleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional study rule \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRegionalStudyRuleManager(_ store: any RegionalStudyRuleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalStudyRuleManager {
        return RegionalStudyRuleManager(
            store: store,
            validator: defaultRegionalStudyRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalStudyRuleEngine(flags)
        )
    }
}
