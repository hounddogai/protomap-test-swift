import AcmePlatform
import Foundation

extension Imaging {
    /// Moves scheduled priority mappings through their life cycle and keeps a journal of what it did.
    final class ScheduledPriorityMappingManager {
        var store: any ScheduledPriorityMappingStore
        var validator: ScheduledPriorityMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledPriorityMappingEngine

        init(store: any ScheduledPriorityMappingStore, validator: ScheduledPriorityMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledPriorityMappingEngine) {
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
                throw Kit.Failure("scheduled priority mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledPriorityMappingStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled priority mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledPriorityMappingStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled priority mapping \(code) not found")
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

    static func newScheduledPriorityMappingManager(_ store: any ScheduledPriorityMappingStore, clock: any Kit.Clocks.Clock) -> ScheduledPriorityMappingManager {
        return ScheduledPriorityMappingManager(
            store: store,
            validator: defaultScheduledPriorityMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledPriorityMappingEngine()
        )
    }
}
