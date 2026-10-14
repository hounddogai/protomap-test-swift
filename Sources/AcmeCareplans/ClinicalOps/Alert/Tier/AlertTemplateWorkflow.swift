import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert templates through their life cycle and keeps a journal of what it did.
    final class AlertTemplateWorkflow {
        var store: any AlertTemplateStore
        var validator: AlertTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertTemplateEngine

        init(store: any AlertTemplateStore, validator: AlertTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertTemplateEngine) {
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
                throw Kit.Failure("alert template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertTemplateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertTemplateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert template \(code) not found")
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

    static func newAlertTemplateWorkflow(_ store: any AlertTemplateStore, clock: any Kit.Clocks.Clock) -> AlertTemplateWorkflow {
        return AlertTemplateWorkflow(
            store: store,
            validator: defaultAlertTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertTemplateEngine()
        )
    }
}
