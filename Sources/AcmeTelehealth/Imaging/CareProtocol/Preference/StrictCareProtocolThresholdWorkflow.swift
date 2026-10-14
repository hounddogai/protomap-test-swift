import AcmePlatform
import Foundation

extension Imaging {
    /// Moves strict care protocol thresholds through their life cycle and keeps a journal of what it did.
    final class StrictCareProtocolThresholdDesk {
        var store: any StrictCareProtocolThresholdStore
        var validator: StrictCareProtocolThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictCareProtocolThresholdEngine

        init(store: any StrictCareProtocolThresholdStore, validator: StrictCareProtocolThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictCareProtocolThresholdEngine) {
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
                throw Kit.Failure("strict care protocol threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictCareProtocolThresholdStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict care protocol threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictCareProtocolThresholdStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict care protocol threshold \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newStrictCareProtocolThresholdDesk(_ store: any StrictCareProtocolThresholdStore, clock: any Kit.Clocks.Clock) -> StrictCareProtocolThresholdDesk {
        return StrictCareProtocolThresholdDesk(
            store: store,
            validator: defaultStrictCareProtocolThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictCareProtocolThresholdEngine()
        )
    }
}
