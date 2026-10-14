import AcmePlatform
import Foundation

extension Consent {
    /// Moves legacy language templates through their life cycle and keeps a journal of what it did.
    final class LegacyLanguageTemplateManager {
        var store: any LegacyLanguageTemplateStore
        var validator: LegacyLanguageTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyLanguageTemplateEngine

        init(store: any LegacyLanguageTemplateStore, validator: LegacyLanguageTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyLanguageTemplateEngine) {
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
                throw Kit.Failure("legacy language template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyLanguageTemplateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy language template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyLanguageTemplateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy language template \(code) not found")
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

    static func newLegacyLanguageTemplateManager(_ store: any LegacyLanguageTemplateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyLanguageTemplateManager {
        return LegacyLanguageTemplateManager(
            store: store,
            validator: defaultLegacyLanguageTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyLanguageTemplateEngine(flags)
        )
    }
}
