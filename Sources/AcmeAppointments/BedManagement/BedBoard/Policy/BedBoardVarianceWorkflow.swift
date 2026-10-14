import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves bed board variances through their life cycle and keeps a journal of what it did.
    final class BedBoardVarianceDesk {
        var store: any BedBoardVarianceStore
        var validator: BedBoardVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any BedBoardVarianceStore, validator: BedBoardVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("bed board variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(BedBoardVarianceStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("bed board variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(BedBoardVarianceStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newBedBoardVarianceDesk(_ store: any BedBoardVarianceStore, clock: any Kit.Clocks.Clock) -> BedBoardVarianceDesk {
        return BedBoardVarianceDesk(
            store: store,
            validator: defaultBedBoardVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
