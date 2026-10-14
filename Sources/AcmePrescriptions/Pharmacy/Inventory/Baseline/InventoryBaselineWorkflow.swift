import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory baselines through their life cycle and keeps a journal of what it did.
    final class InventoryBaselineManager {
        var store: any InventoryBaselineStore
        var validator: InventoryBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryBaselineEngine

        init(store: any InventoryBaselineStore, validator: InventoryBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryBaselineEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryBaselineStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryBaselineStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory baseline \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newInventoryBaselineManager(_ store: any InventoryBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> InventoryBaselineManager {
        return InventoryBaselineManager(
            store: store,
            validator: defaultInventoryBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryBaselineEngine(flags)
        )
    }
}
