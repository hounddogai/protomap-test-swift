import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted remittance requests through their life cycle and keeps a journal of what it did.
    final class WeightedRemittanceRequestService {
        var store: any WeightedRemittanceRequestStore
        var validator: WeightedRemittanceRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedRemittanceRequestEngine

        init(store: any WeightedRemittanceRequestStore, validator: WeightedRemittanceRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedRemittanceRequestEngine) {
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
                throw Kit.Failure("weighted remittance request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedRemittanceRequestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted remittance request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedRemittanceRequestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted remittance request \(code) not found")
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

    static func newWeightedRemittanceRequestService(_ store: any WeightedRemittanceRequestStore, clock: any Kit.Clocks.Clock) -> WeightedRemittanceRequestService {
        return WeightedRemittanceRequestService(
            store: store,
            validator: defaultWeightedRemittanceRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedRemittanceRequestEngine()
        )
    }
}
