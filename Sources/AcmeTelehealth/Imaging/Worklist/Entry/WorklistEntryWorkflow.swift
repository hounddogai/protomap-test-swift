import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist entries through their life cycle and keeps a journal of what it did.
    final class WorklistEntryDesk {
        var store: any WorklistEntryStore
        var validator: WorklistEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistEntryStore, validator: WorklistEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("worklist entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistEntryStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistEntryStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newWorklistEntryDesk(_ store: any WorklistEntryStore, clock: any Kit.Clocks.Clock) -> WorklistEntryDesk {
        return WorklistEntryDesk(store: store, validator: defaultWorklistEntryValidator(), clock: clock, journal: [])
    }
}
