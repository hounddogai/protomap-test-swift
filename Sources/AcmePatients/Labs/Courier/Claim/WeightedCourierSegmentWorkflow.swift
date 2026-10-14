import AcmePlatform
import Foundation

extension Labs {
    /// Moves weighted courier segments through their life cycle and keeps a journal of what it did.
    final class WeightedCourierSegmentWorkflow {
        var store: any WeightedCourierSegmentStore
        var validator: WeightedCourierSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedCourierSegmentStore, validator: WeightedCourierSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted courier segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedCourierSegmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted courier segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedCourierSegmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newWeightedCourierSegmentWorkflow(_ store: any WeightedCourierSegmentStore, clock: any Kit.Clocks.Clock) -> WeightedCourierSegmentWorkflow {
        return WeightedCourierSegmentWorkflow(
            store: store,
            validator: defaultWeightedCourierSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
