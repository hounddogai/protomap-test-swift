import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted isolation segments through their life cycle and keeps a journal of what it did.
    final class WeightedIsolationSegmentCoordinator {
        var store: any WeightedIsolationSegmentStore
        var validator: WeightedIsolationSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedIsolationSegmentStore, validator: WeightedIsolationSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted isolation segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedIsolationSegmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted isolation segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedIsolationSegmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newWeightedIsolationSegmentCoordinator(_ store: any WeightedIsolationSegmentStore, clock: any Kit.Clocks.Clock) -> WeightedIsolationSegmentCoordinator {
        return WeightedIsolationSegmentCoordinator(
            store: store,
            validator: defaultWeightedIsolationSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
