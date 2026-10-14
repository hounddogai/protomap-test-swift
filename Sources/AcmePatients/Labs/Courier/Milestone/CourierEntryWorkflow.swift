import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier entries through their life cycle and keeps a journal of what it did.
    final class CourierEntryManager {
        var store: any CourierEntryStore
        var validator: CourierEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierEntryEngine

        init(store: any CourierEntryStore, validator: CourierEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierEntryEngine) {
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
                throw Kit.Failure("courier entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier entry \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCourierEntryManager(_ store: any CourierEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CourierEntryManager {
        return CourierEntryManager(
            store: store,
            validator: defaultCourierEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierEntryEngine(flags)
        )
    }
}
