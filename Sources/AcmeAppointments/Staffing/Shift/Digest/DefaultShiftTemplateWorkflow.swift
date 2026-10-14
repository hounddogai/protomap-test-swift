import AcmePlatform
import Foundation

extension Staffing {
    /// Moves default shift templates through their life cycle and keeps a journal of what it did.
    final class DefaultShiftTemplateManager {
        var store: any DefaultShiftTemplateStore
        var validator: DefaultShiftTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultShiftTemplateEngine

        init(store: any DefaultShiftTemplateStore, validator: DefaultShiftTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultShiftTemplateEngine) {
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
                throw Kit.Failure("default shift template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultShiftTemplateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default shift template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultShiftTemplateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default shift template \(code) not found")
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

    static func newDefaultShiftTemplateManager(_ store: any DefaultShiftTemplateStore, clock: any Kit.Clocks.Clock) -> DefaultShiftTemplateManager {
        return DefaultShiftTemplateManager(
            store: store,
            validator: defaultDefaultShiftTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultShiftTemplateEngine()
        )
    }
}
