import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves legacy outreach drafts through their life cycle and keeps a journal of what it did.
    final class LegacyOutreachDraftWorkflow {
        var store: any LegacyOutreachDraftStore
        var validator: LegacyOutreachDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyOutreachDraftStore, validator: LegacyOutreachDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy outreach draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyOutreachDraftStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy outreach draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyOutreachDraftStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newLegacyOutreachDraftWorkflow(_ store: any LegacyOutreachDraftStore, clock: any Kit.Clocks.Clock) -> LegacyOutreachDraftWorkflow {
        return LegacyOutreachDraftWorkflow(
            store: store,
            validator: defaultLegacyOutreachDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
