import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary allocations through their life cycle and keeps a journal of what it did.
    final class FormularyAllocationManager {
        var store: any FormularyAllocationStore
        var validator: FormularyAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyAllocationEngine

        init(store: any FormularyAllocationStore, validator: FormularyAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyAllocationEngine) {
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
                throw Kit.Failure("formulary allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyAllocationStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyAllocationStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary allocation \(code) not found")
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

    static func newFormularyAllocationManager(_ store: any FormularyAllocationStore, clock: any Kit.Clocks.Clock) -> FormularyAllocationManager {
        return FormularyAllocationManager(
            store: store,
            validator: defaultFormularyAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyAllocationEngine()
        )
    }
}
