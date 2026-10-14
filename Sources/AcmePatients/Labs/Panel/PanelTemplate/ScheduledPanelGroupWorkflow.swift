import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled panel groups through their life cycle and keeps a journal of what it did.
    final class ScheduledPanelGroupDesk {
        var store: any ScheduledPanelGroupStore
        var validator: ScheduledPanelGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledPanelGroupEngine

        init(store: any ScheduledPanelGroupStore, validator: ScheduledPanelGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledPanelGroupEngine) {
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
                throw Kit.Failure("scheduled panel group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledPanelGroupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled panel group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledPanelGroupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled panel group \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newScheduledPanelGroupDesk(_ store: any ScheduledPanelGroupStore, clock: any Kit.Clocks.Clock) -> ScheduledPanelGroupDesk {
        return ScheduledPanelGroupDesk(
            store: store,
            validator: defaultScheduledPanelGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledPanelGroupEngine()
        )
    }
}
