import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory bundles through their life cycle and keeps a journal of what it did.
    final class InventoryBundleService {
        var store: any InventoryBundleStore
        var validator: InventoryBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryBundleEngine

        init(store: any InventoryBundleStore, validator: InventoryBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryBundleEngine) {
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
                throw Kit.Failure("inventory bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryBundleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryBundleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory bundle \(code) not found")
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

    static func newInventoryBundleService(_ store: any InventoryBundleStore, clock: any Kit.Clocks.Clock) -> InventoryBundleService {
        return InventoryBundleService(
            store: store,
            validator: defaultInventoryBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryBundleEngine()
        )
    }
}
