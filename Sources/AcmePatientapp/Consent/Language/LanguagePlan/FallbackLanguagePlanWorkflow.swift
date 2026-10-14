import AcmePlatform
import Foundation

extension Consent {
    /// Moves fallback language plans through their life cycle and keeps a journal of what it did.
    final class FallbackLanguagePlanCoordinator {
        var store: any FallbackLanguagePlanStore
        var validator: FallbackLanguagePlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackLanguagePlanEngine

        init(store: any FallbackLanguagePlanStore, validator: FallbackLanguagePlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackLanguagePlanEngine) {
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
                throw Kit.Failure("fallback language plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackLanguagePlanStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback language plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackLanguagePlanStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback language plan \(code) not found")
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

    static func newFallbackLanguagePlanCoordinator(_ store: any FallbackLanguagePlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackLanguagePlanCoordinator {
        return FallbackLanguagePlanCoordinator(
            store: store,
            validator: defaultFallbackLanguagePlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackLanguagePlanEngine(flags)
        )
    }
}
