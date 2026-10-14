import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves scheduled denial baselines through their life cycle and keeps a journal of what it did.
    final class ScheduledDenialBaselineService {
        var store: any ScheduledDenialBaselineStore
        var validator: ScheduledDenialBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledDenialBaselineEngine

        init(store: any ScheduledDenialBaselineStore, validator: ScheduledDenialBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledDenialBaselineEngine) {
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
                throw Kit.Failure("scheduled denial baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledDenialBaselineStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled denial baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledDenialBaselineStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled denial baseline \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newScheduledDenialBaselineService(_ store: any ScheduledDenialBaselineStore, clock: any Kit.Clocks.Clock) -> ScheduledDenialBaselineService {
        return ScheduledDenialBaselineService(
            store: store,
            validator: defaultScheduledDenialBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledDenialBaselineEngine()
        )
    }
}
