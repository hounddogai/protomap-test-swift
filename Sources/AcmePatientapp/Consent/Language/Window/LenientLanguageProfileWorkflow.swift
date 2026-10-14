import AcmePlatform
import Foundation

extension Consent {
    /// Moves lenient language profiles through their life cycle and keeps a journal of what it did.
    final class LenientLanguageProfileWorkflow {
        var store: any LenientLanguageProfileStore
        var validator: LenientLanguageProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientLanguageProfileEngine

        init(store: any LenientLanguageProfileStore, validator: LenientLanguageProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientLanguageProfileEngine) {
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
                throw Kit.Failure("lenient language profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientLanguageProfileStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient language profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientLanguageProfileStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient language profile \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newLenientLanguageProfileWorkflow(_ store: any LenientLanguageProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientLanguageProfileWorkflow {
        return LenientLanguageProfileWorkflow(
            store: store,
            validator: defaultLenientLanguageProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientLanguageProfileEngine(flags)
        )
    }
}
