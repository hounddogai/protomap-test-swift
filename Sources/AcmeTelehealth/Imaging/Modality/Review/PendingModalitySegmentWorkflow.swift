import AcmePlatform
import Foundation

extension Imaging {
    /// Moves pending modality segments through their life cycle and keeps a journal of what it did.
    final class PendingModalitySegmentDesk {
        var store: any PendingModalitySegmentStore
        var validator: PendingModalitySegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingModalitySegmentStore, validator: PendingModalitySegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending modality segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingModalitySegmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending modality segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingModalitySegmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newPendingModalitySegmentDesk(_ store: any PendingModalitySegmentStore, clock: any Kit.Clocks.Clock) -> PendingModalitySegmentDesk {
        return PendingModalitySegmentDesk(
            store: store,
            validator: defaultPendingModalitySegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
