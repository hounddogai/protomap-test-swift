import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set metrics through their life cycle and keeps a journal of what it did.
    final class OrderSetMetricService {
        var store: any OrderSetMetricStore
        var validator: OrderSetMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OrderSetMetricEngine

        init(store: any OrderSetMetricStore, validator: OrderSetMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OrderSetMetricEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetMetricStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetMetricStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set metric \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newOrderSetMetricService(_ store: any OrderSetMetricStore, clock: any Kit.Clocks.Clock) -> OrderSetMetricService {
        return OrderSetMetricService(
            store: store,
            validator: defaultOrderSetMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultOrderSetMetricEngine()
        )
    }
}
