import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel reservations through their life cycle and keeps a journal of what it did.
    final class PanelReservationService {
        var store: any PanelReservationStore
        var validator: PanelReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelReservationEngine

        init(store: any PanelReservationStore, validator: PanelReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelReservationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelReservationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelReservationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel reservation \(code) not found")
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

    static func newPanelReservationService(_ store: any PanelReservationStore, clock: any Kit.Clocks.Clock) -> PanelReservationService {
        return PanelReservationService(
            store: store,
            validator: defaultPanelReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelReservationEngine()
        )
    }
}
