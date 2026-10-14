import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves tiered formulary templates through their life cycle and keeps a journal of what it did.
    final class TieredFormularyTemplateWorkflow {
        var store: any TieredFormularyTemplateStore
        var validator: TieredFormularyTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredFormularyTemplateEngine

        init(store: any TieredFormularyTemplateStore, validator: TieredFormularyTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredFormularyTemplateEngine) {
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
                throw Kit.Failure("tiered formulary template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredFormularyTemplateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered formulary template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredFormularyTemplateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered formulary template \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newTieredFormularyTemplateWorkflow(_ store: any TieredFormularyTemplateStore, clock: any Kit.Clocks.Clock) -> TieredFormularyTemplateWorkflow {
        return TieredFormularyTemplateWorkflow(
            store: store,
            validator: defaultTieredFormularyTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredFormularyTemplateEngine()
        )
    }
}
