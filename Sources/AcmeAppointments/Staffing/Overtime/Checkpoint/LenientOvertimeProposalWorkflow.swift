import AcmePlatform
import Foundation

extension Staffing {
    /// Moves lenient overtime proposals through their life cycle and keeps a journal of what it did.
    final class LenientOvertimeProposalDesk {
        var store: any LenientOvertimeProposalStore
        var validator: LenientOvertimeProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientOvertimeProposalStore, validator: LenientOvertimeProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient overtime proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientOvertimeProposalStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient overtime proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientOvertimeProposalStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newLenientOvertimeProposalDesk(_ store: any LenientOvertimeProposalStore, clock: any Kit.Clocks.Clock) -> LenientOvertimeProposalDesk {
        return LenientOvertimeProposalDesk(
            store: store,
            validator: defaultLenientOvertimeProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
