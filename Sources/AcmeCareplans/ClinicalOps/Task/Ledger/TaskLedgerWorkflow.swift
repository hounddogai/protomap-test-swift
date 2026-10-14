import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves task ledgers through their life cycle and keeps a journal of what it did.
    final class TaskLedgerCoordinator {
        var store: any TaskLedgerStore
        var validator: TaskLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TaskLedgerStore, validator: TaskLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("task ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TaskLedgerStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("task ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TaskLedgerStatus.cancelled)
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

    static func newTaskLedgerCoordinator(_ store: any TaskLedgerStore, clock: any Kit.Clocks.Clock) -> TaskLedgerCoordinator {
        return TaskLedgerCoordinator(
            store: store,
            validator: defaultTaskLedgerValidator(),
            clock: clock,
            journal: []
        )
    }
}
