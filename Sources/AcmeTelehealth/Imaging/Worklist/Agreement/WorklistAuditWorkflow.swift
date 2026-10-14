import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist audits through their life cycle and keeps a journal of what it did.
    final class WorklistAuditWorkflow {
        var store: any WorklistAuditStore
        var validator: WorklistAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistAuditStore, validator: WorklistAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("worklist audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newWorklistAuditWorkflow(_ store: any WorklistAuditStore, clock: any Kit.Clocks.Clock) -> WorklistAuditWorkflow {
        return WorklistAuditWorkflow(
            store: store,
            validator: defaultWorklistAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
