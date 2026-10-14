import AcmePlatform
import Foundation

extension Labs {
    /// Moves result reservations through their life cycle and keeps a journal of what it did.
    final class ResultReservationService {
        var store: any ResultReservationStore
        var validator: ResultReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ResultReservationStore, validator: ResultReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("result reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ResultReservationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("result reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ResultReservationStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newResultReservationService(_ store: any ResultReservationStore, clock: any Kit.Clocks.Clock) -> ResultReservationService {
        return ResultReservationService(
            store: store,
            validator: defaultResultReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
