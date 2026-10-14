import AcmePlatform
import Foundation

extension Consent {
    /// Moves primary consent form entries through their life cycle and keeps a journal of what it did.
    final class PrimaryConsentFormEntryManager {
        var store: any PrimaryConsentFormEntryStore
        var validator: PrimaryConsentFormEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryConsentFormEntryStore, validator: PrimaryConsentFormEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary consent form entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryConsentFormEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary consent form entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryConsentFormEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newPrimaryConsentFormEntryManager(_ store: any PrimaryConsentFormEntryStore, clock: any Kit.Clocks.Clock) -> PrimaryConsentFormEntryManager {
        return PrimaryConsentFormEntryManager(
            store: store,
            validator: defaultPrimaryConsentFormEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
