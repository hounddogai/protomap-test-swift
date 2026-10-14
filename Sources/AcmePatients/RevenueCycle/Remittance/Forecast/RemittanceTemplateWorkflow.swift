import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance templates through their life cycle and keeps a journal of what it did.
    final class RemittanceTemplateManager {
        var store: any RemittanceTemplateStore
        var validator: RemittanceTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceTemplateEngine

        init(store: any RemittanceTemplateStore, validator: RemittanceTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceTemplateEngine) {
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
                throw Kit.Failure("remittance template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceTemplateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceTemplateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance template \(code) not found")
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

    static func newRemittanceTemplateManager(_ store: any RemittanceTemplateStore, clock: any Kit.Clocks.Clock) -> RemittanceTemplateManager {
        return RemittanceTemplateManager(
            store: store,
            validator: defaultRemittanceTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceTemplateEngine()
        )
    }
}
