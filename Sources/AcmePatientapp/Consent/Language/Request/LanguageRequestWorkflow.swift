import AcmePlatform
import Foundation

extension Consent {
    /// Moves language requests through their life cycle and keeps a journal of what it did.
    final class LanguageRequestCoordinator {
        var store: any LanguageRequestStore
        var validator: LanguageRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LanguageRequestEngine

        init(store: any LanguageRequestStore, validator: LanguageRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LanguageRequestEngine) {
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
                throw Kit.Failure("language request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("language request \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newLanguageRequestCoordinator(_ store: any LanguageRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LanguageRequestCoordinator {
        return LanguageRequestCoordinator(
            store: store,
            validator: defaultLanguageRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLanguageRequestEngine(flags)
        )
    }
}
