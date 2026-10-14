import AcmePlatform
import Foundation

extension Labs {
    /// Moves legacy result schedules through their life cycle and keeps a journal of what it did.
    final class LegacyResultScheduleDesk {
        var store: any LegacyResultScheduleStore
        var validator: LegacyResultScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyResultScheduleEngine

        init(store: any LegacyResultScheduleStore, validator: LegacyResultScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyResultScheduleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy result schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyResultScheduleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy result schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyResultScheduleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy result schedule \(code) not found")
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

    static func newLegacyResultScheduleDesk(_ store: any LegacyResultScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyResultScheduleDesk {
        return LegacyResultScheduleDesk(
            store: store,
            validator: defaultLegacyResultScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyResultScheduleEngine(flags)
        )
    }
}
