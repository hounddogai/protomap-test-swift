import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves default census reservations through their life cycle and keeps a journal of what it did.
    final class DefaultCensusReservationService {
        var store: any DefaultCensusReservationStore
        var validator: DefaultCensusReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCensusReservationEngine

        init(store: any DefaultCensusReservationStore, validator: DefaultCensusReservationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCensusReservationEngine) {
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
                throw Kit.Failure("default census reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCensusReservationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default census reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCensusReservationStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default census reservation \(code) not found")
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

    static func newDefaultCensusReservationService(_ store: any DefaultCensusReservationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCensusReservationService {
        return DefaultCensusReservationService(
            store: store,
            validator: defaultDefaultCensusReservationValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCensusReservationEngine(flags)
        )
    }
}
