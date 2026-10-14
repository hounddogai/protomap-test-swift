import AcmePlatform
import Foundation

extension Imaging {
    /// Moves care protocol templates through their life cycle and keeps a journal of what it did.
    final class CareProtocolTemplateManager {
        var store: any CareProtocolTemplateStore
        var validator: CareProtocolTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolTemplateEngine

        init(store: any CareProtocolTemplateStore, validator: CareProtocolTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolTemplateEngine) {
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
                throw Kit.Failure("care protocol template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolTemplateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolTemplateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol template \(code) not found")
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

    static func newCareProtocolTemplateManager(_ store: any CareProtocolTemplateStore, clock: any Kit.Clocks.Clock) -> CareProtocolTemplateManager {
        return CareProtocolTemplateManager(
            store: store,
            validator: defaultCareProtocolTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolTemplateEngine()
        )
    }
}
