import AcmePlatform
import Foundation

extension Imaging {
    /// Moves legacy study segments through their life cycle and keeps a journal of what it did.
    final class LegacyStudySegmentWorkflow {
        var store: any LegacyStudySegmentStore
        var validator: LegacyStudySegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyStudySegmentEngine

        init(store: any LegacyStudySegmentStore, validator: LegacyStudySegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyStudySegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy study segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyStudySegmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy study segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyStudySegmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy study segment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newLegacyStudySegmentWorkflow(_ store: any LegacyStudySegmentStore, clock: any Kit.Clocks.Clock) -> LegacyStudySegmentWorkflow {
        return LegacyStudySegmentWorkflow(
            store: store,
            validator: defaultLegacyStudySegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyStudySegmentEngine()
        )
    }
}
