import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves legacy dispense entries through their life cycle and keeps a journal of what it did.
    final class LegacyDispenseEntryCoordinator {
        var store: any LegacyDispenseEntryStore
        var validator: LegacyDispenseEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyDispenseEntryEngine

        init(store: any LegacyDispenseEntryStore, validator: LegacyDispenseEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyDispenseEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy dispense entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyDispenseEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy dispense entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyDispenseEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy dispense entry \(code) not found")
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

    static func newLegacyDispenseEntryCoordinator(_ store: any LegacyDispenseEntryStore, clock: any Kit.Clocks.Clock) -> LegacyDispenseEntryCoordinator {
        return LegacyDispenseEntryCoordinator(
            store: store,
            validator: defaultLegacyDispenseEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyDispenseEntryEngine()
        )
    }
}
