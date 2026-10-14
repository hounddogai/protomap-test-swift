import AcmePlatform
import Foundation

extension Consent {
    /// Moves capped language preferences through their life cycle and keeps a journal of what it did.
    final class CappedLanguagePreferenceService {
        var store: any CappedLanguagePreferenceStore
        var validator: CappedLanguagePreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedLanguagePreferenceStore, validator: CappedLanguagePreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped language preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedLanguagePreferenceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped language preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedLanguagePreferenceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newCappedLanguagePreferenceService(_ store: any CappedLanguagePreferenceStore, clock: any Kit.Clocks.Clock) -> CappedLanguagePreferenceService {
        return CappedLanguagePreferenceService(
            store: store,
            validator: defaultCappedLanguagePreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
