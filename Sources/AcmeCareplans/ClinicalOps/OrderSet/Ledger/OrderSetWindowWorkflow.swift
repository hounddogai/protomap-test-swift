import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set windows through their life cycle and keeps a journal of what it did.
    final class OrderSetWindowDesk {
        var store: any OrderSetWindowStore
        var validator: OrderSetWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OrderSetWindowEngine

        init(store: any OrderSetWindowStore, validator: OrderSetWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OrderSetWindowEngine) {
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
                throw Kit.Failure("order set window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetWindowStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetWindowStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set window \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newOrderSetWindowDesk(_ store: any OrderSetWindowStore, clock: any Kit.Clocks.Clock) -> OrderSetWindowDesk {
        return OrderSetWindowDesk(
            store: store,
            validator: defaultOrderSetWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultOrderSetWindowEngine()
        )
    }
}
