import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy inventory rollups through their life cycle and keeps a journal of what it did.
    final class LegacyInventoryRollupService {
        var store: any LegacyInventoryRollupStore
        var validator: LegacyInventoryRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyInventoryRollupEngine

        init(store: any LegacyInventoryRollupStore, validator: LegacyInventoryRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyInventoryRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy inventory rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyInventoryRollupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy inventory rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyInventoryRollupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy inventory rollup \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newLegacyInventoryRollupService(_ store: any LegacyInventoryRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyInventoryRollupService {
        return LegacyInventoryRollupService(
            store: store,
            validator: defaultLegacyInventoryRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyInventoryRollupEngine(flags)
        )
    }
}
