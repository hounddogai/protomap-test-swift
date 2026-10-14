import AcmePlatform
import Foundation

extension Imaging {
    /// Moves weighted priority reservations through their life cycle and keeps a journal of what it did.
    final class WeightedPriorityReservationService {
        var store: any WeightedPriorityReservationStore
        var validator: WeightedPriorityReservationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedPriorityReservationStore, validator: WeightedPriorityReservationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted priority reservation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedPriorityReservationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted priority reservation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedPriorityReservationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newWeightedPriorityReservationService(_ store: any WeightedPriorityReservationStore, clock: any Kit.Clocks.Clock) -> WeightedPriorityReservationService {
        return WeightedPriorityReservationService(
            store: store,
            validator: defaultWeightedPriorityReservationValidator(),
            clock: clock,
            journal: []
        )
    }
}
