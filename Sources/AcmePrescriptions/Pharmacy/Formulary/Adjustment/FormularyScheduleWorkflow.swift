import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary schedules through their life cycle and keeps a journal of what it did.
    final class FormularyScheduleWorkflow {
        var store: any FormularyScheduleStore
        var validator: FormularyScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyScheduleEngine

        init(store: any FormularyScheduleStore, validator: FormularyScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyScheduleEngine) {
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
                throw Kit.Failure("formulary schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyScheduleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyScheduleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary schedule \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newFormularyScheduleWorkflow(_ store: any FormularyScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FormularyScheduleWorkflow {
        return FormularyScheduleWorkflow(
            store: store,
            validator: defaultFormularyScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyScheduleEngine(flags)
        )
    }
}
