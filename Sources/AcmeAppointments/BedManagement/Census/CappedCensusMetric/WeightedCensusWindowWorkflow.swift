import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted census windows through their life cycle and keeps a journal of what it did.
    final class WeightedCensusWindowService {
        var store: any WeightedCensusWindowStore
        var validator: WeightedCensusWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedCensusWindowStore, validator: WeightedCensusWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted census window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedCensusWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted census window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedCensusWindowStatus.failed)
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

    static func newWeightedCensusWindowService(_ store: any WeightedCensusWindowStore, clock: any Kit.Clocks.Clock) -> WeightedCensusWindowService {
        return WeightedCensusWindowService(
            store: store,
            validator: defaultWeightedCensusWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
