import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending reference range allocations through their life cycle and keeps a journal of what it did.
    final class PendingReferenceRangeAllocationManager {
        var store: any PendingReferenceRangeAllocationStore
        var validator: PendingReferenceRangeAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingReferenceRangeAllocationStore, validator: PendingReferenceRangeAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending reference range allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingReferenceRangeAllocationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending reference range allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingReferenceRangeAllocationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newPendingReferenceRangeAllocationManager(_ store: any PendingReferenceRangeAllocationStore, clock: any Kit.Clocks.Clock) -> PendingReferenceRangeAllocationManager {
        return PendingReferenceRangeAllocationManager(
            store: store,
            validator: defaultPendingReferenceRangeAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
