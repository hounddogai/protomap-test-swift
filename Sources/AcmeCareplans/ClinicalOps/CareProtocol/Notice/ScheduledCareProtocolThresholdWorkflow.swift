import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves scheduled care protocol thresholds through their life cycle and keeps a journal of what it did.
    final class ScheduledCareProtocolThresholdService {
        var store: any ScheduledCareProtocolThresholdStore
        var validator: ScheduledCareProtocolThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledCareProtocolThresholdEngine

        init(store: any ScheduledCareProtocolThresholdStore, validator: ScheduledCareProtocolThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledCareProtocolThresholdEngine) {
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
                throw Kit.Failure("scheduled care protocol threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCareProtocolThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCareProtocolThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol threshold \(code) not found")
            }
            let result = engine.run(item)
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

    static func newScheduledCareProtocolThresholdService(_ store: any ScheduledCareProtocolThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledCareProtocolThresholdService {
        return ScheduledCareProtocolThresholdService(
            store: store,
            validator: defaultScheduledCareProtocolThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledCareProtocolThresholdEngine(flags)
        )
    }
}
