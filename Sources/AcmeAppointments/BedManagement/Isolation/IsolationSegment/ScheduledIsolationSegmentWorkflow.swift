import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled isolation segments through their life cycle and keeps a journal of what it did.
    final class ScheduledIsolationSegmentService {
        var store: any ScheduledIsolationSegmentStore
        var validator: ScheduledIsolationSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledIsolationSegmentEngine

        init(store: any ScheduledIsolationSegmentStore, validator: ScheduledIsolationSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledIsolationSegmentEngine) {
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
                throw Kit.Failure("scheduled isolation segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledIsolationSegmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled isolation segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledIsolationSegmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled isolation segment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newScheduledIsolationSegmentService(_ store: any ScheduledIsolationSegmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledIsolationSegmentService {
        return ScheduledIsolationSegmentService(
            store: store,
            validator: defaultScheduledIsolationSegmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledIsolationSegmentEngine(flags)
        )
    }
}
