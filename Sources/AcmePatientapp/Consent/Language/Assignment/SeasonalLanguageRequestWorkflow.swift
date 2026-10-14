import AcmePlatform
import Foundation

extension Consent {
    /// Moves seasonal language requests through their life cycle and keeps a journal of what it did.
    final class SeasonalLanguageRequestManager {
        var store: any SeasonalLanguageRequestStore
        var validator: SeasonalLanguageRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalLanguageRequestEngine

        init(store: any SeasonalLanguageRequestStore, validator: SeasonalLanguageRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalLanguageRequestEngine) {
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
                throw Kit.Failure("seasonal language request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalLanguageRequestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal language request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalLanguageRequestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal language request \(code) not found")
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

    static func newSeasonalLanguageRequestManager(_ store: any SeasonalLanguageRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalLanguageRequestManager {
        return SeasonalLanguageRequestManager(
            store: store,
            validator: defaultSeasonalLanguageRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalLanguageRequestEngine(flags)
        )
    }
}
