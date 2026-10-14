import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set entries through their life cycle and keeps a journal of what it did.
    final class OrderSetEntryService {
        var store: any OrderSetEntryStore
        var validator: OrderSetEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OrderSetEntryStore, validator: OrderSetEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("order set entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetEntryStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetEntryStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newOrderSetEntryService(_ store: any OrderSetEntryStore, clock: any Kit.Clocks.Clock) -> OrderSetEntryService {
        return OrderSetEntryService(
            store: store,
            validator: defaultOrderSetEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
