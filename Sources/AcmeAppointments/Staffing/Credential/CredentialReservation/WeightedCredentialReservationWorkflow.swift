import AcmePlatform
import Foundation

extension Staffing {
    /// Moves weighted credential reservations through their life cycle and keeps a journal of what it did.
    final class WeightedCredentialReservationService {
        var store: any WeightedCredentialReservationStore
        var validator: WeightedCredentialReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedCredentialReservationEngine

        init(store: any WeightedCredentialReservationStore, validator: WeightedCredentialReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedCredentialReservationEngine) {
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
                throw Kit.Failure("weighted credential reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedCredentialReservationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted credential reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedCredentialReservationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted credential reservation \(code) not found")
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

    static func newWeightedCredentialReservationService(_ store: any WeightedCredentialReservationStore, clock: any Kit.Clocks.Clock) -> WeightedCredentialReservationService {
        return WeightedCredentialReservationService(
            store: store,
            validator: defaultWeightedCredentialReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedCredentialReservationEngine()
        )
    }
}
