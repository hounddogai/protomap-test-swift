import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist groups through their life cycle and keeps a journal of what it did.
    final class WorklistGroupDesk {
        var store: any WorklistGroupStore
        var validator: WorklistGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistGroupStore, validator: WorklistGroupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("worklist group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistGroupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistGroupStatus.retired)
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

    static func newWorklistGroupDesk(_ store: any WorklistGroupStore, clock: any Kit.Clocks.Clock) -> WorklistGroupDesk {
        return WorklistGroupDesk(store: store, validator: defaultWorklistGroupValidator(), clock: clock, journal: [])
    }
}
