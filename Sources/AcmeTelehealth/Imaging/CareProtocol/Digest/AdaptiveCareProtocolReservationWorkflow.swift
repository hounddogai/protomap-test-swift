import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive care protocol reservations through their life cycle and keeps a journal of what it did.
    final class AdaptiveCareProtocolReservationManager {
        var store: any AdaptiveCareProtocolReservationStore
        var validator: AdaptiveCareProtocolReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveCareProtocolReservationEngine

        init(store: any AdaptiveCareProtocolReservationStore, validator: AdaptiveCareProtocolReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveCareProtocolReservationEngine) {
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
                throw Kit.Failure("adaptive care protocol reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveCareProtocolReservationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care protocol reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveCareProtocolReservationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care protocol reservation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAdaptiveCareProtocolReservationManager(_ store: any AdaptiveCareProtocolReservationStore, clock: any Kit.Clocks.Clock) -> AdaptiveCareProtocolReservationManager {
        return AdaptiveCareProtocolReservationManager(
            store: store,
            validator: defaultAdaptiveCareProtocolReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveCareProtocolReservationEngine()
        )
    }
}
