import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional accession reservations through their life cycle and keeps a journal of what it did.
    final class RegionalAccessionReservationDesk {
        var store: any RegionalAccessionReservationStore
        var validator: RegionalAccessionReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalAccessionReservationEngine

        init(store: any RegionalAccessionReservationStore, validator: RegionalAccessionReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalAccessionReservationEngine) {
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
                throw Kit.Failure("regional accession reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalAccessionReservationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional accession reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalAccessionReservationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional accession reservation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newRegionalAccessionReservationDesk(_ store: any RegionalAccessionReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalAccessionReservationDesk {
        return RegionalAccessionReservationDesk(
            store: store,
            validator: defaultRegionalAccessionReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalAccessionReservationEngine(flags)
        )
    }
}
