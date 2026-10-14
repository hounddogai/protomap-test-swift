import AcmePlatform
import Foundation

extension Consent {
    /// Moves language reviews through their life cycle and keeps a journal of what it did.
    final class LanguageReviewWorkflow {
        var store: any LanguageReviewStore
        var validator: LanguageReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageReviewEngine

        init(store: any LanguageReviewStore, validator: LanguageReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageReviewEngine) {
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
                throw Kit.Failure("language review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageReviewStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageReviewStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language review \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newLanguageReviewWorkflow(_ store: any LanguageReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LanguageReviewWorkflow {
        return LanguageReviewWorkflow(
            store: store,
            validator: defaultLanguageReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageReviewEngine(flags)
        )
    }
}
