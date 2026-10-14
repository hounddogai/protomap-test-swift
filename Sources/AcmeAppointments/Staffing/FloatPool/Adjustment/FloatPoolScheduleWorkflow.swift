import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool schedules through their life cycle and keeps a journal of what it did.
    final class FloatPoolScheduleDesk {
        var store: any FloatPoolScheduleStore
        var validator: FloatPoolScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolScheduleEngine

        init(store: any FloatPoolScheduleStore, validator: FloatPoolScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolScheduleEngine) {
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
                throw Kit.Failure("float pool schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolScheduleStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolScheduleStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool schedule \(code) not found")
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

    static func newFloatPoolScheduleDesk(_ store: any FloatPoolScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FloatPoolScheduleDesk {
        return FloatPoolScheduleDesk(
            store: store,
            validator: defaultFloatPoolScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolScheduleEngine(flags)
        )
    }
}
