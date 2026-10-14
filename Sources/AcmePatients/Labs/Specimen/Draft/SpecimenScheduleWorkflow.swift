import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen schedules through their life cycle and keeps a journal of what it did.
    final class SpecimenScheduleManager {
        var store: any SpecimenScheduleStore
        var validator: SpecimenScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenScheduleEngine

        init(store: any SpecimenScheduleStore, validator: SpecimenScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenScheduleEngine) {
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
                throw Kit.Failure("specimen schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenScheduleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen schedule \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newSpecimenScheduleManager(_ store: any SpecimenScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenScheduleManager {
        return SpecimenScheduleManager(
            store: store,
            validator: defaultSpecimenScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenScheduleEngine(flags)
        )
    }
}
