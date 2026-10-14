import AcmePlatform
import Foundation

extension Consent {
    /// Moves language profiles through their life cycle and keeps a journal of what it did.
    final class LanguageProfileService {
        var store: any LanguageProfileStore
        var validator: LanguageProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LanguageProfileStore, validator: LanguageProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("language profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newLanguageProfileService(_ store: any LanguageProfileStore, clock: any Kit.Clocks.Clock) -> LanguageProfileService {
        return LanguageProfileService(
            store: store,
            validator: defaultLanguageProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
