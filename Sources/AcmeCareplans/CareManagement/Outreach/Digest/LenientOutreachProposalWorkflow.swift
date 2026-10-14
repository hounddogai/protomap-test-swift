import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient outreach proposals through their life cycle and keeps a journal of what it did.
    final class LenientOutreachProposalDesk {
        var store: any LenientOutreachProposalStore
        var validator: LenientOutreachProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientOutreachProposalStore, validator: LenientOutreachProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient outreach proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientOutreachProposalStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient outreach proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientOutreachProposalStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newLenientOutreachProposalDesk(_ store: any LenientOutreachProposalStore, clock: any Kit.Clocks.Clock) -> LenientOutreachProposalDesk {
        return LenientOutreachProposalDesk(
            store: store,
            validator: defaultLenientOutreachProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
