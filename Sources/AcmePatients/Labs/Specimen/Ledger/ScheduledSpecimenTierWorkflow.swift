import AcmePlatform
import Foundation

extension Labs {
    /// Moves scheduled specimen tiers through their life cycle and keeps a journal of what it did.
    final class ScheduledSpecimenTierDesk {
        var store: any ScheduledSpecimenTierStore
        var validator: ScheduledSpecimenTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledSpecimenTierEngine

        init(store: any ScheduledSpecimenTierStore, validator: ScheduledSpecimenTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledSpecimenTierEngine) {
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
                throw Kit.Failure("scheduled specimen tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledSpecimenTierStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled specimen tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledSpecimenTierStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled specimen tier \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newScheduledSpecimenTierDesk(_ store: any ScheduledSpecimenTierStore, clock: any Kit.Clocks.Clock) -> ScheduledSpecimenTierDesk {
        return ScheduledSpecimenTierDesk(
            store: store,
            validator: defaultScheduledSpecimenTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledSpecimenTierEngine()
        )
    }
}
