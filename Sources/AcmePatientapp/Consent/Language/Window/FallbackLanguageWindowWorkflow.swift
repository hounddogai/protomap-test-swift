import AcmePlatform
import Foundation

extension Consent {
    /// Moves fallback language windows through their life cycle and keeps a journal of what it did.
    final class FallbackLanguageWindowWorkflow {
        var store: any FallbackLanguageWindowStore
        var validator: FallbackLanguageWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackLanguageWindowStore, validator: FallbackLanguageWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback language window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackLanguageWindowStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback language window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackLanguageWindowStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newFallbackLanguageWindowWorkflow(_ store: any FallbackLanguageWindowStore, clock: any Kit.Clocks.Clock) -> FallbackLanguageWindowWorkflow {
        return FallbackLanguageWindowWorkflow(
            store: store,
            validator: defaultFallbackLanguageWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
