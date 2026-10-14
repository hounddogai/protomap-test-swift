import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol budgets through their life cycle and keeps a journal of what it did.
    final class CareProtocolBudgetManager {
        var store: any CareProtocolBudgetStore
        var validator: CareProtocolBudgetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolBudgetEngine

        init(store: any CareProtocolBudgetStore, validator: CareProtocolBudgetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolBudgetEngine) {
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
                throw Kit.Failure("care protocol budget \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolBudgetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol budget \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolBudgetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol budget \(code) not found")
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

    static func newCareProtocolBudgetManager(_ store: any CareProtocolBudgetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareProtocolBudgetManager {
        return CareProtocolBudgetManager(
            store: store,
            validator: defaultCareProtocolBudgetValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolBudgetEngine(flags)
        )
    }
}
