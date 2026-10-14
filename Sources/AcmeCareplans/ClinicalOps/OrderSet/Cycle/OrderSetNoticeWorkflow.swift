import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set notices through their life cycle and keeps a journal of what it did.
    final class OrderSetNoticeWorkflow {
        var store: any OrderSetNoticeStore
        var validator: OrderSetNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OrderSetNoticeStore, validator: OrderSetNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("order set notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newOrderSetNoticeWorkflow(_ store: any OrderSetNoticeStore, clock: any Kit.Clocks.Clock) -> OrderSetNoticeWorkflow {
        return OrderSetNoticeWorkflow(
            store: store,
            validator: defaultOrderSetNoticeValidator(),
            clock: clock,
            journal: []
        )
    }
}
