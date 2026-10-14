import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance thresholds through their life cycle and keeps a journal of what it did.
    final class RemittanceThresholdService {
        var store: any RemittanceThresholdStore
        var validator: RemittanceThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceThresholdEngine

        init(store: any RemittanceThresholdStore, validator: RemittanceThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceThresholdEngine) {
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
                throw Kit.Failure("remittance threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceThresholdStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceThresholdStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance threshold \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newRemittanceThresholdService(_ store: any RemittanceThresholdStore, clock: any Kit.Clocks.Clock) -> RemittanceThresholdService {
        return RemittanceThresholdService(
            store: store,
            validator: defaultRemittanceThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceThresholdEngine()
        )
    }
}
