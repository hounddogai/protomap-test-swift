import AcmePlatform
import Foundation

extension Labs {
    /// Moves manual courier metrics through their life cycle and keeps a journal of what it did.
    final class ManualCourierMetricDesk {
        var store: any ManualCourierMetricStore
        var validator: ManualCourierMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualCourierMetricStore, validator: ManualCourierMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual courier metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualCourierMetricStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual courier metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualCourierMetricStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newManualCourierMetricDesk(_ store: any ManualCourierMetricStore, clock: any Kit.Clocks.Clock) -> ManualCourierMetricDesk {
        return ManualCourierMetricDesk(
            store: store,
            validator: defaultManualCourierMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
