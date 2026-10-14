import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning templates through their life cycle and keeps a journal of what it did.
    final class CleaningTemplateManager {
        var store: any CleaningTemplateStore
        var validator: CleaningTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CleaningTemplateEngine

        init(store: any CleaningTemplateStore, validator: CleaningTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CleaningTemplateEngine) {
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
                throw Kit.Failure("cleaning template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningTemplateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningTemplateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning template \(code) not found")
            }
            let result = engine.price(item)
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

    static func newCleaningTemplateManager(_ store: any CleaningTemplateStore, clock: any Kit.Clocks.Clock) -> CleaningTemplateManager {
        return CleaningTemplateManager(
            store: store,
            validator: defaultCleaningTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultCleaningTemplateEngine()
        )
    }
}
