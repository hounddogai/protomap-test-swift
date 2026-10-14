import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional panel rules through their life cycle and keeps a journal of what it did.
    final class RegionalPanelRuleManager {
        var store: any RegionalPanelRuleStore
        var validator: RegionalPanelRuleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalPanelRuleStore, validator: RegionalPanelRuleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional panel rule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalPanelRuleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional panel rule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalPanelRuleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newRegionalPanelRuleManager(_ store: any RegionalPanelRuleStore, clock: any Kit.Clocks.Clock) -> RegionalPanelRuleManager {
        return RegionalPanelRuleManager(
            store: store,
            validator: defaultRegionalPanelRuleValidator(),
            clock: clock,
            journal: []
        )
    }
}
