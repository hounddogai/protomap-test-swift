import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves lenient bed board drafts through their life cycle and keeps a journal of what it did.
    final class LenientBedBoardDraftCoordinator {
        var store: any LenientBedBoardDraftStore
        var validator: LenientBedBoardDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientBedBoardDraftStore, validator: LenientBedBoardDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient bed board draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientBedBoardDraftStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient bed board draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientBedBoardDraftStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newLenientBedBoardDraftCoordinator(_ store: any LenientBedBoardDraftStore, clock: any Kit.Clocks.Clock) -> LenientBedBoardDraftCoordinator {
        return LenientBedBoardDraftCoordinator(
            store: store,
            validator: defaultLenientBedBoardDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
