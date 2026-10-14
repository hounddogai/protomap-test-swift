import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves default remittance templates through their life cycle and keeps a journal of what it did.
    final class DefaultRemittanceTemplateManager {
        var store: any DefaultRemittanceTemplateStore
        var validator: DefaultRemittanceTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultRemittanceTemplateEngine

        init(store: any DefaultRemittanceTemplateStore, validator: DefaultRemittanceTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultRemittanceTemplateEngine) {
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
                throw Kit.Failure("default remittance template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultRemittanceTemplateStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default remittance template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultRemittanceTemplateStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default remittance template \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDefaultRemittanceTemplateManager(_ store: any DefaultRemittanceTemplateStore, clock: any Kit.Clocks.Clock) -> DefaultRemittanceTemplateManager {
        return DefaultRemittanceTemplateManager(
            store: store,
            validator: defaultDefaultRemittanceTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultRemittanceTemplateEngine()
        )
    }
}
