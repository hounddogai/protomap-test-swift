import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set reservations through their life cycle and keeps a journal of what it did.
    final class OrderSetReservationCoordinator {
        var store: any OrderSetReservationStore
        var validator: OrderSetReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OrderSetReservationEngine

        init(store: any OrderSetReservationStore, validator: OrderSetReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OrderSetReservationEngine) {
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
                throw Kit.Failure("order set reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetReservationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetReservationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set reservation \(code) not found")
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

    static func newOrderSetReservationCoordinator(_ store: any OrderSetReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OrderSetReservationCoordinator {
        return OrderSetReservationCoordinator(
            store: store,
            validator: defaultOrderSetReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultOrderSetReservationEngine(flags)
        )
    }
}
