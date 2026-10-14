import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form preferences through their life cycle and keeps a journal of what it did.
    final class ConsentFormPreferenceDesk {
        var store: any ConsentFormPreferenceStore
        var validator: ConsentFormPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ConsentFormPreferenceStore, validator: ConsentFormPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("consent form preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormPreferenceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormPreferenceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newConsentFormPreferenceDesk(_ store: any ConsentFormPreferenceStore, clock: any Kit.Clocks.Clock) -> ConsentFormPreferenceDesk {
        return ConsentFormPreferenceDesk(
            store: store,
            validator: defaultConsentFormPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
