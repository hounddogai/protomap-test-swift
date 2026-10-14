import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range segments through their life cycle and keeps a journal of what it did.
    final class ReferenceRangeSegmentWorkflow {
        var store: any ReferenceRangeSegmentStore
        var validator: ReferenceRangeSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferenceRangeSegmentStore, validator: ReferenceRangeSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("reference range segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangeSegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangeSegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newReferenceRangeSegmentWorkflow(_ store: any ReferenceRangeSegmentStore, clock: any Kit.Clocks.Clock) -> ReferenceRangeSegmentWorkflow {
        return ReferenceRangeSegmentWorkflow(
            store: store,
            validator: defaultReferenceRangeSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
