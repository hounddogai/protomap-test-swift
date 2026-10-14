import AcmePlatform
import Foundation

extension Consent {
    /// Moves language preferences through their life cycle and keeps a journal of what it did.
    final class LanguagePreferenceCoordinator {
        var store: any LanguagePreferenceStore
        var validator: LanguagePreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguagePreferenceEngine

        init(store: any LanguagePreferenceStore, validator: LanguagePreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguagePreferenceEngine) {
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
                throw Kit.Failure("language preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguagePreferenceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguagePreferenceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language preference \(code) not found")
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

    static func newLanguagePreferenceCoordinator(_ store: any LanguagePreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LanguagePreferenceCoordinator {
        return LanguagePreferenceCoordinator(
            store: store,
            validator: defaultLanguagePreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguagePreferenceEngine(flags)
        )
    }
}
