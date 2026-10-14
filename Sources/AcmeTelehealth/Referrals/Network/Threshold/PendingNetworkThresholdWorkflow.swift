import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending network thresholds through their life cycle and keeps a journal of what it did.
    final class PendingNetworkThresholdWorkflow {
        var store: any PendingNetworkThresholdStore
        var validator: PendingNetworkThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingNetworkThresholdEngine

        init(store: any PendingNetworkThresholdStore, validator: PendingNetworkThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingNetworkThresholdEngine) {
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
                throw Kit.Failure("pending network threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingNetworkThresholdStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending network threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingNetworkThresholdStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending network threshold \(code) not found")
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

    static func newPendingNetworkThresholdWorkflow(_ store: any PendingNetworkThresholdStore, clock: any Kit.Clocks.Clock) -> PendingNetworkThresholdWorkflow {
        return PendingNetworkThresholdWorkflow(
            store: store,
            validator: defaultPendingNetworkThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingNetworkThresholdEngine()
        )
    }
}
