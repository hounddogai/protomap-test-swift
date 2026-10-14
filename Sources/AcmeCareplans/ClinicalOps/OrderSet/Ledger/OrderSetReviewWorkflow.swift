import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set reviews through their life cycle and keeps a journal of what it did.
    final class OrderSetReviewManager {
        var store: any OrderSetReviewStore
        var validator: OrderSetReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OrderSetReviewStore, validator: OrderSetReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("order set review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetReviewStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetReviewStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newOrderSetReviewManager(_ store: any OrderSetReviewStore, clock: any Kit.Clocks.Clock) -> OrderSetReviewManager {
        return OrderSetReviewManager(
            store: store,
            validator: defaultOrderSetReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
