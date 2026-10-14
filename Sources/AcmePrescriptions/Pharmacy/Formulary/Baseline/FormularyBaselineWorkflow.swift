import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary baselines through their life cycle and keeps a journal of what it did.
    final class FormularyBaselineService {
        var store: any FormularyBaselineStore
        var validator: FormularyBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyBaselineEngine

        init(store: any FormularyBaselineStore, validator: FormularyBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyBaselineEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyBaselineStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyBaselineStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary baseline \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFormularyBaselineService(_ store: any FormularyBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FormularyBaselineService {
        return FormularyBaselineService(
            store: store,
            validator: defaultFormularyBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyBaselineEngine(flags)
        )
    }
}
