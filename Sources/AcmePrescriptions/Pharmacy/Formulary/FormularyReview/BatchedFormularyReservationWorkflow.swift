import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves batched formulary reservations through their life cycle and keeps a journal of what it did.
    final class BatchedFormularyReservationDesk {
        var store: any BatchedFormularyReservationStore
        var validator: BatchedFormularyReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: BatchedFormularyReservationEngine

        init(store: any BatchedFormularyReservationStore, validator: BatchedFormularyReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: BatchedFormularyReservationEngine) {
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
                throw Kit.Failure("batched formulary reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BatchedFormularyReservationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched formulary reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BatchedFormularyReservationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("batched formulary reservation \(code) not found")
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

    static func newBatchedFormularyReservationDesk(_ store: any BatchedFormularyReservationStore, clock: any Kit.Clocks.Clock) -> BatchedFormularyReservationDesk {
        return BatchedFormularyReservationDesk(
            store: store,
            validator: defaultBatchedFormularyReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultBatchedFormularyReservationEngine()
        )
    }
}
