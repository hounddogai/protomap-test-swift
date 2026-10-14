import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global rounding templates through their life cycle and keeps a journal of what it did.
    final class GlobalRoundingTemplateWorkflow {
        var store: any GlobalRoundingTemplateStore
        var validator: GlobalRoundingTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalRoundingTemplateEngine

        init(store: any GlobalRoundingTemplateStore, validator: GlobalRoundingTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalRoundingTemplateEngine) {
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
                throw Kit.Failure("global rounding template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalRoundingTemplateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global rounding template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalRoundingTemplateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global rounding template \(code) not found")
            }
            let result = engine.price(item)
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

    static func newGlobalRoundingTemplateWorkflow(_ store: any GlobalRoundingTemplateStore, clock: any Kit.Clocks.Clock) -> GlobalRoundingTemplateWorkflow {
        return GlobalRoundingTemplateWorkflow(
            store: store,
            validator: defaultGlobalRoundingTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalRoundingTemplateEngine()
        )
    }
}
