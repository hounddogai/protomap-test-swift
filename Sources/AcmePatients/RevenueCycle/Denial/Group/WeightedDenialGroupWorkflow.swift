import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted denial groups through their life cycle and keeps a journal of what it did.
    final class WeightedDenialGroupDesk {
        var store: any WeightedDenialGroupStore
        var validator: WeightedDenialGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedDenialGroupStore, validator: WeightedDenialGroupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted denial group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedDenialGroupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted denial group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedDenialGroupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newWeightedDenialGroupDesk(_ store: any WeightedDenialGroupStore, clock: any Kit.Clocks.Clock) -> WeightedDenialGroupDesk {
        return WeightedDenialGroupDesk(
            store: store,
            validator: defaultWeightedDenialGroupValidator(),
            clock: clock,
            journal: []
        )
    }
}
