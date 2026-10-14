import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled reference range segments through their life cycle and keeps a journal of what it did.
    final class ScheduledReferenceRangeSegmentDesk {
        var store: any ScheduledReferenceRangeSegmentStore
        var validator: ScheduledReferenceRangeSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledReferenceRangeSegmentEngine

        init(store: any ScheduledReferenceRangeSegmentStore, validator: ScheduledReferenceRangeSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledReferenceRangeSegmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled reference range segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledReferenceRangeSegmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled reference range segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledReferenceRangeSegmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled reference range segment \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newScheduledReferenceRangeSegmentDesk(_ store: any ScheduledReferenceRangeSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledReferenceRangeSegmentDesk {
        return ScheduledReferenceRangeSegmentDesk(
            store: store,
            validator: defaultScheduledReferenceRangeSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledReferenceRangeSegmentEngine(flags)
        )
    }
}
