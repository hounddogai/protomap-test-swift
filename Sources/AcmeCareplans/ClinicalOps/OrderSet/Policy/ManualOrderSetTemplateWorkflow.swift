import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves manual order set templates through their life cycle and keeps a journal of what it did.
    final class ManualOrderSetTemplateDesk {
        var store: any ManualOrderSetTemplateStore
        var validator: ManualOrderSetTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualOrderSetTemplateEngine

        init(store: any ManualOrderSetTemplateStore, validator: ManualOrderSetTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualOrderSetTemplateEngine) {
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
                throw Kit.Failure("manual order set template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualOrderSetTemplateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual order set template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualOrderSetTemplateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual order set template \(code) not found")
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

    static func newManualOrderSetTemplateDesk(_ store: any ManualOrderSetTemplateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualOrderSetTemplateDesk {
        return ManualOrderSetTemplateDesk(
            store: store,
            validator: defaultManualOrderSetTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualOrderSetTemplateEngine(flags)
        )
    }
}
