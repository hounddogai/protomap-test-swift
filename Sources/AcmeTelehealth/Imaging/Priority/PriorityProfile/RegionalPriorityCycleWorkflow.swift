import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional priority cycles through their life cycle and keeps a journal of what it did.
    final class RegionalPriorityCycleManager {
        var store: any RegionalPriorityCycleStore
        var validator: RegionalPriorityCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalPriorityCycleEngine

        init(store: any RegionalPriorityCycleStore, validator: RegionalPriorityCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalPriorityCycleEngine) {
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
                throw Kit.Failure("regional priority cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalPriorityCycleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional priority cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalPriorityCycleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional priority cycle \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRegionalPriorityCycleManager(_ store: any RegionalPriorityCycleStore, clock: any Kit.Clocks.Clock) -> RegionalPriorityCycleManager {
        return RegionalPriorityCycleManager(
            store: store,
            validator: defaultRegionalPriorityCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalPriorityCycleEngine()
        )
    }
}
