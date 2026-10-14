import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read plans through their life cycle and keeps a journal of what it did.
    final class ReadPlanWorkflow {
        var store: any ReadPlanStore
        var validator: ReadPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReadPlanStore, validator: ReadPlanValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("read plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadPlanStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadPlanStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newReadPlanWorkflow(_ store: any ReadPlanStore, clock: any Kit.Clocks.Clock) -> ReadPlanWorkflow {
        return ReadPlanWorkflow(store: store, validator: defaultReadPlanValidator(), clock: clock, journal: [])
    }
}
