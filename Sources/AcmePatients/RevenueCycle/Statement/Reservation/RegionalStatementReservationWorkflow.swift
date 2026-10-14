import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves regional statement reservations through their life cycle and keeps a journal of what it did.
    final class RegionalStatementReservationWorkflow {
        var store: any RegionalStatementReservationStore
        var validator: RegionalStatementReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalStatementReservationEngine

        init(store: any RegionalStatementReservationStore, validator: RegionalStatementReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalStatementReservationEngine) {
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
                throw Kit.Failure("regional statement reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalStatementReservationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional statement reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalStatementReservationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional statement reservation \(code) not found")
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

    static func newRegionalStatementReservationWorkflow(_ store: any RegionalStatementReservationStore, clock: any Kit.Clocks.Clock) -> RegionalStatementReservationWorkflow {
        return RegionalStatementReservationWorkflow(
            store: store,
            validator: defaultRegionalStatementReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalStatementReservationEngine()
        )
    }
}
