import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board proposals through their life cycle and keeps a journal of what it did.
    final class BedBoardProposalDesk {
        var store: any BedBoardProposalStore
        var validator: BedBoardProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BedBoardProposalStore, validator: BedBoardProposalValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("bed board proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardProposalStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardProposalStatus.expired)
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

    static func newBedBoardProposalDesk(_ store: any BedBoardProposalStore, clock: any Kit.Clocks.Clock) -> BedBoardProposalDesk {
        return BedBoardProposalDesk(
            store: store,
            validator: defaultBedBoardProposalValidator(),
            clock: clock,
            journal: []
        )
    }
}
