import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional result reservations through their life cycle and keeps a journal of what it did.
    final class RegionalResultReservationManager {
        var store: any RegionalResultReservationStore
        var validator: RegionalResultReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalResultReservationEngine

        init(store: any RegionalResultReservationStore, validator: RegionalResultReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalResultReservationEngine) {
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
                throw Kit.Failure("regional result reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalResultReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional result reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalResultReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional result reservation \(code) not found")
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

    static func newRegionalResultReservationManager(_ store: any RegionalResultReservationStore, clock: any Kit.Clocks.Clock) -> RegionalResultReservationManager {
        return RegionalResultReservationManager(
            store: store,
            validator: defaultRegionalResultReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalResultReservationEngine()
        )
    }
}
