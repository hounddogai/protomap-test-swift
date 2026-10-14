import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap reservations through their life cycle and keeps a journal of what it did.
    final class CareGapReservationWorkflow {
        var store: any CareGapReservationStore
        var validator: CareGapReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapReservationEngine

        init(store: any CareGapReservationStore, validator: CareGapReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapReservationEngine) {
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
                throw Kit.Failure("care gap reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapReservationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapReservationStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap reservation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newCareGapReservationWorkflow(_ store: any CareGapReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareGapReservationWorkflow {
        return CareGapReservationWorkflow(
            store: store,
            validator: defaultCareGapReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapReservationEngine(flags)
        )
    }
}
