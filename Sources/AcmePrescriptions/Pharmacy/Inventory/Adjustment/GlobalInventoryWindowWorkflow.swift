import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves global inventory windows through their life cycle and keeps a journal of what it did.
    final class GlobalInventoryWindowDesk {
        var store: any GlobalInventoryWindowStore
        var validator: GlobalInventoryWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalInventoryWindowEngine

        init(store: any GlobalInventoryWindowStore, validator: GlobalInventoryWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalInventoryWindowEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global inventory window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalInventoryWindowStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global inventory window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalInventoryWindowStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global inventory window \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newGlobalInventoryWindowDesk(_ store: any GlobalInventoryWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalInventoryWindowDesk {
        return GlobalInventoryWindowDesk(
            store: store,
            validator: defaultGlobalInventoryWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalInventoryWindowEngine(flags)
        )
    }
}
