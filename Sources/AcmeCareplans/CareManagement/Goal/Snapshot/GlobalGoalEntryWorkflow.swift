import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves global goal entries through their life cycle and keeps a journal of what it did.
    final class GlobalGoalEntryManager {
        var store: any GlobalGoalEntryStore
        var validator: GlobalGoalEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalGoalEntryEngine

        init(store: any GlobalGoalEntryStore, validator: GlobalGoalEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalGoalEntryEngine) {
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
                throw Kit.Failure("global goal entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalGoalEntryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global goal entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalGoalEntryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global goal entry \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newGlobalGoalEntryManager(_ store: any GlobalGoalEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalGoalEntryManager {
        return GlobalGoalEntryManager(
            store: store,
            validator: defaultGlobalGoalEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalGoalEntryEngine(flags)
        )
    }
}
