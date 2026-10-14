import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves statement slots through their life cycle and keeps a journal of what it did.
    final class StatementSlotService {
        var store: any StatementSlotStore
        var validator: StatementSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StatementSlotEngine

        init(store: any StatementSlotStore, validator: StatementSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StatementSlotEngine) {
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
                throw Kit.Failure("statement slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StatementSlotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StatementSlotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("statement slot \(code) not found")
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

    static func newStatementSlotService(_ store: any StatementSlotStore, clock: any Kit.Clocks.Clock) -> StatementSlotService {
        return StatementSlotService(
            store: store,
            validator: defaultStatementSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultStatementSlotEngine()
        )
    }
}
