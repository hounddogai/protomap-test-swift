import AcmePlatform
import Foundation

extension Consent {
    /// Moves language tiers through their life cycle and keeps a journal of what it did.
    final class LanguageTierWorkflow {
        var store: any LanguageTierStore
        var validator: LanguageTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageTierEngine

        init(store: any LanguageTierStore, validator: LanguageTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageTierEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageTierStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageTierStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language tier \(code) not found")
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

    static func newLanguageTierWorkflow(_ store: any LanguageTierStore, clock: any Kit.Clocks.Clock) -> LanguageTierWorkflow {
        return LanguageTierWorkflow(
            store: store,
            validator: defaultLanguageTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageTierEngine()
        )
    }
}
