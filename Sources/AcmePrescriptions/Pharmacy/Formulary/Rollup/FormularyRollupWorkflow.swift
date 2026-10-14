import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary rollups through their life cycle and keeps a journal of what it did.
    final class FormularyRollupCoordinator {
        var store: any FormularyRollupStore
        var validator: FormularyRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyRollupEngine

        init(store: any FormularyRollupStore, validator: FormularyRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyRollupEngine) {
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
                throw Kit.Failure("formulary rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyRollupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyRollupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary rollup \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newFormularyRollupCoordinator(_ store: any FormularyRollupStore, clock: any Kit.Clocks.Clock) -> FormularyRollupCoordinator {
        return FormularyRollupCoordinator(
            store: store,
            validator: defaultFormularyRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyRollupEngine()
        )
    }
}
