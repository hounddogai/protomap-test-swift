import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves strict bed board drafts through their life cycle and keeps a journal of what it did.
    final class StrictBedBoardDraftWorkflow {
        var store: any StrictBedBoardDraftStore
        var validator: StrictBedBoardDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictBedBoardDraftStore, validator: StrictBedBoardDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict bed board draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictBedBoardDraftStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict bed board draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictBedBoardDraftStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newStrictBedBoardDraftWorkflow(_ store: any StrictBedBoardDraftStore, clock: any Kit.Clocks.Clock) -> StrictBedBoardDraftWorkflow {
        return StrictBedBoardDraftWorkflow(
            store: store,
            validator: defaultStrictBedBoardDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
