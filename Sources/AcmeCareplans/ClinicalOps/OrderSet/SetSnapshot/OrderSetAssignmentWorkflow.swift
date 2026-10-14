import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves order set assignments through their life cycle and keeps a journal of what it did.
    final class OrderSetAssignmentManager {
        var store: any OrderSetAssignmentStore
        var validator: OrderSetAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OrderSetAssignmentStore, validator: OrderSetAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("order set assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OrderSetAssignmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("order set assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OrderSetAssignmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newOrderSetAssignmentManager(_ store: any OrderSetAssignmentStore, clock: any Kit.Clocks.Clock) -> OrderSetAssignmentManager {
        return OrderSetAssignmentManager(
            store: store,
            validator: defaultOrderSetAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
