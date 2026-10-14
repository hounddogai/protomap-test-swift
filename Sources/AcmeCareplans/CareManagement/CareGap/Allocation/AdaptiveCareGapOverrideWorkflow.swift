import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves adaptive care gap overrides through their life cycle and keeps a journal of what it did.
    final class AdaptiveCareGapOverrideWorkflow {
        var store: any AdaptiveCareGapOverrideStore
        var validator: AdaptiveCareGapOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveCareGapOverrideEngine

        init(store: any AdaptiveCareGapOverrideStore, validator: AdaptiveCareGapOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveCareGapOverrideEngine) {
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
                throw Kit.Failure("adaptive care gap override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveCareGapOverrideStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care gap override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveCareGapOverrideStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive care gap override \(code) not found")
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

    static func newAdaptiveCareGapOverrideWorkflow(_ store: any AdaptiveCareGapOverrideStore, clock: any Kit.Clocks.Clock) -> AdaptiveCareGapOverrideWorkflow {
        return AdaptiveCareGapOverrideWorkflow(
            store: store,
            validator: defaultAdaptiveCareGapOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveCareGapOverrideEngine()
        )
    }
}
