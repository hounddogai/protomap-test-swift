import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary read reservations through their life cycle and keeps a journal of what it did.
    final class PrimaryReadReservationWorkflow {
        var store: any PrimaryReadReservationStore
        var validator: PrimaryReadReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryReadReservationEngine

        init(store: any PrimaryReadReservationStore, validator: PrimaryReadReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryReadReservationEngine) {
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
                throw Kit.Failure("primary read reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryReadReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary read reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryReadReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary read reservation \(code) not found")
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

    static func newPrimaryReadReservationWorkflow(_ store: any PrimaryReadReservationStore, clock: any Kit.Clocks.Clock) -> PrimaryReadReservationWorkflow {
        return PrimaryReadReservationWorkflow(
            store: store,
            validator: defaultPrimaryReadReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryReadReservationEngine()
        )
    }
}
