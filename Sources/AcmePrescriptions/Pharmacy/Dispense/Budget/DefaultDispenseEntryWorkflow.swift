import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves default dispense entries through their life cycle and keeps a journal of what it did.
    final class DefaultDispenseEntryCoordinator {
        var store: any DefaultDispenseEntryStore
        var validator: DefaultDispenseEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultDispenseEntryEngine

        init(store: any DefaultDispenseEntryStore, validator: DefaultDispenseEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultDispenseEntryEngine) {
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
                throw Kit.Failure("default dispense entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultDispenseEntryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default dispense entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultDispenseEntryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default dispense entry \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newDefaultDispenseEntryCoordinator(_ store: any DefaultDispenseEntryStore, clock: any Kit.Clocks.Clock) -> DefaultDispenseEntryCoordinator {
        return DefaultDispenseEntryCoordinator(
            store: store,
            validator: defaultDefaultDispenseEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultDispenseEntryEngine()
        )
    }
}
