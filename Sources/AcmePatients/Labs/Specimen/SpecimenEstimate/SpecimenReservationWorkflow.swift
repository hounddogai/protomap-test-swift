import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen reservations through their life cycle and keeps a journal of what it did.
    final class SpecimenReservationCoordinator {
        var store: any SpecimenReservationStore
        var validator: SpecimenReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenReservationEngine

        init(store: any SpecimenReservationStore, validator: SpecimenReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenReservationEngine) {
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
                throw Kit.Failure("specimen reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenReservationStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenReservationStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen reservation \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newSpecimenReservationCoordinator(_ store: any SpecimenReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenReservationCoordinator {
        return SpecimenReservationCoordinator(
            store: store,
            validator: defaultSpecimenReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenReservationEngine(flags)
        )
    }
}
