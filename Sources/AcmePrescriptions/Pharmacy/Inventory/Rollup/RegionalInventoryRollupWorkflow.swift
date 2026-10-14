import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves regional inventory rollups through their life cycle and keeps a journal of what it did.
    final class RegionalInventoryRollupDesk {
        var store: any RegionalInventoryRollupStore
        var validator: RegionalInventoryRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalInventoryRollupStore, validator: RegionalInventoryRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional inventory rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalInventoryRollupStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional inventory rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalInventoryRollupStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newRegionalInventoryRollupDesk(_ store: any RegionalInventoryRollupStore, clock: any Kit.Clocks.Clock) -> RegionalInventoryRollupDesk {
        return RegionalInventoryRollupDesk(
            store: store,
            validator: defaultRegionalInventoryRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
