import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves weighted recall notices through their life cycle and keeps a journal of what it did.
    final class WeightedRecallNoticeWorkflow {
        var store: any WeightedRecallNoticeStore
        var validator: WeightedRecallNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedRecallNoticeStore, validator: WeightedRecallNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted recall notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedRecallNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted recall notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedRecallNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newWeightedRecallNoticeWorkflow(_ store: any WeightedRecallNoticeStore, clock: any Kit.Clocks.Clock) -> WeightedRecallNoticeWorkflow {
        return WeightedRecallNoticeWorkflow(
            store: store,
            validator: defaultWeightedRecallNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
