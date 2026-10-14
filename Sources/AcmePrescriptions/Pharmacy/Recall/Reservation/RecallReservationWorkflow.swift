import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall reservations through their life cycle and keeps a journal of what it did.
    final class RecallReservationManager {
        var store: any RecallReservationStore
        var validator: RecallReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallReservationEngine

        init(store: any RecallReservationStore, validator: RecallReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallReservationEngine) {
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
                throw Kit.Failure("recall reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallReservationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallReservationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall reservation \(code) not found")
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

    static func newRecallReservationManager(_ store: any RecallReservationStore, clock: any Kit.Clocks.Clock) -> RecallReservationManager {
        return RecallReservationManager(
            store: store,
            validator: defaultRecallReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallReservationEngine()
        )
    }
}
