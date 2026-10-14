import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves adaptive statement reservations through their life cycle and keeps a journal of what it did.
    final class AdaptiveStatementReservationCoordinator {
        var store: any AdaptiveStatementReservationStore
        var validator: AdaptiveStatementReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveStatementReservationStore, validator: AdaptiveStatementReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive statement reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveStatementReservationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive statement reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveStatementReservationStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newAdaptiveStatementReservationCoordinator(_ store: any AdaptiveStatementReservationStore, clock: any Kit.Clocks.Clock) -> AdaptiveStatementReservationCoordinator {
        return AdaptiveStatementReservationCoordinator(
            store: store,
            validator: defaultAdaptiveStatementReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
