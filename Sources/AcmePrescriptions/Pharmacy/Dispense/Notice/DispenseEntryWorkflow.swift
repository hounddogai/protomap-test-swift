import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense entries through their life cycle and keeps a journal of what it did.
    final class DispenseEntryManager {
        var store: any DispenseEntryStore
        var validator: DispenseEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispenseEntryEngine

        init(store: any DispenseEntryStore, validator: DispenseEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispenseEntryEngine) {
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
                throw Kit.Failure("dispense entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseEntryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseEntryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense entry \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newDispenseEntryManager(_ store: any DispenseEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DispenseEntryManager {
        return DispenseEntryManager(
            store: store,
            validator: defaultDispenseEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispenseEntryEngine(flags)
        )
    }
}
