import AcmePlatform
import Foundation

extension Imaging {
    /// Moves pending read reservations through their life cycle and keeps a journal of what it did.
    final class PendingReadReservationWorkflow {
        var store: any PendingReadReservationStore
        var validator: PendingReadReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingReadReservationEngine

        init(store: any PendingReadReservationStore, validator: PendingReadReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingReadReservationEngine) {
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
                throw Kit.Failure("pending read reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingReadReservationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending read reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingReadReservationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending read reservation \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newPendingReadReservationWorkflow(_ store: any PendingReadReservationStore, clock: any Kit.Clocks.Clock) -> PendingReadReservationWorkflow {
        return PendingReadReservationWorkflow(
            store: store,
            validator: defaultPendingReadReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingReadReservationEngine()
        )
    }
}
