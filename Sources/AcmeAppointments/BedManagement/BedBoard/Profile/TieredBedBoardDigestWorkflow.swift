import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves tiered bed board digests through their life cycle and keeps a journal of what it did.
    final class TieredBedBoardDigestDesk {
        var store: any TieredBedBoardDigestStore
        var validator: TieredBedBoardDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredBedBoardDigestStore, validator: TieredBedBoardDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered bed board digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredBedBoardDigestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered bed board digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredBedBoardDigestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newTieredBedBoardDigestDesk(_ store: any TieredBedBoardDigestStore, clock: any Kit.Clocks.Clock) -> TieredBedBoardDigestDesk {
        return TieredBedBoardDigestDesk(
            store: store,
            validator: defaultTieredBedBoardDigestValidator(),
            clock: clock,
            journal: []
        )
    }
}
