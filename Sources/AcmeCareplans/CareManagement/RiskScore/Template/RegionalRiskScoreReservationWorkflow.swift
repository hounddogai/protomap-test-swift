import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves regional risk score reservations through their life cycle and keeps a journal of what it did.
    final class RegionalRiskScoreReservationWorkflow {
        var store: any RegionalRiskScoreReservationStore
        var validator: RegionalRiskScoreReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalRiskScoreReservationStore, validator: RegionalRiskScoreReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional risk score reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalRiskScoreReservationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional risk score reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalRiskScoreReservationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRegionalRiskScoreReservationWorkflow(_ store: any RegionalRiskScoreReservationStore, clock: any Kit.Clocks.Clock) -> RegionalRiskScoreReservationWorkflow {
        return RegionalRiskScoreReservationWorkflow(
            store: store,
            validator: defaultRegionalRiskScoreReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
