import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves tiered outreach rules through their life cycle and keeps a journal of what it did.
    final class TieredOutreachRuleDesk {
        var store: any TieredOutreachRuleStore
        var validator: TieredOutreachRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredOutreachRuleEngine

        init(store: any TieredOutreachRuleStore, validator: TieredOutreachRuleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredOutreachRuleEngine) {
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
                throw Kit.Failure("tiered outreach rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredOutreachRuleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered outreach rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredOutreachRuleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered outreach rule \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newTieredOutreachRuleDesk(_ store: any TieredOutreachRuleStore, clock: any Kit.Clocks.Clock) -> TieredOutreachRuleDesk {
        return TieredOutreachRuleDesk(
            store: store,
            validator: defaultTieredOutreachRuleValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredOutreachRuleEngine()
        )
    }
}
