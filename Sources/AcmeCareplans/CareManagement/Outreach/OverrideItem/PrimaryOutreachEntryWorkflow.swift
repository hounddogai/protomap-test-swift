import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves primary outreach entries through their life cycle and keeps a journal of what it did.
    final class PrimaryOutreachEntryDesk {
        var store: any PrimaryOutreachEntryStore
        var validator: PrimaryOutreachEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryOutreachEntryStore, validator: PrimaryOutreachEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary outreach entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryOutreachEntryStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary outreach entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryOutreachEntryStatus.archived)
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

    static func newPrimaryOutreachEntryDesk(_ store: any PrimaryOutreachEntryStore, clock: any Kit.Clocks.Clock) -> PrimaryOutreachEntryDesk {
        return PrimaryOutreachEntryDesk(
            store: store,
            validator: defaultPrimaryOutreachEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
