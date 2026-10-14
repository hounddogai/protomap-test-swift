import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves global bed board drafts through their life cycle and keeps a journal of what it did.
    final class GlobalBedBoardDraftService {
        var store: any GlobalBedBoardDraftStore
        var validator: GlobalBedBoardDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalBedBoardDraftStore, validator: GlobalBedBoardDraftValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("global bed board draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalBedBoardDraftStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global bed board draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalBedBoardDraftStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newGlobalBedBoardDraftService(_ store: any GlobalBedBoardDraftStore, clock: any Kit.Clocks.Clock) -> GlobalBedBoardDraftService {
        return GlobalBedBoardDraftService(
            store: store,
            validator: defaultGlobalBedBoardDraftValidator(),
            clock: clock,
            journal: []
        )
    }
}
