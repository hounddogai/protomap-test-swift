import AcmePlatform
import Foundation

extension Imaging {
    /// Moves manual study segments through their life cycle and keeps a journal of what it did.
    final class ManualStudySegmentManager {
        var store: any ManualStudySegmentStore
        var validator: ManualStudySegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualStudySegmentStore, validator: ManualStudySegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual study segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualStudySegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual study segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualStudySegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newManualStudySegmentManager(_ store: any ManualStudySegmentStore, clock: any Kit.Clocks.Clock) -> ManualStudySegmentManager {
        return ManualStudySegmentManager(
            store: store,
            validator: defaultManualStudySegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
