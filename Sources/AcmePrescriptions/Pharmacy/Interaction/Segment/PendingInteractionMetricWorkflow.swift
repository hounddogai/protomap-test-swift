import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves pending interaction metrics through their life cycle and keeps a journal of what it did.
    final class PendingInteractionMetricWorkflow {
        var store: any PendingInteractionMetricStore
        var validator: PendingInteractionMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingInteractionMetricEngine

        init(store: any PendingInteractionMetricStore, validator: PendingInteractionMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingInteractionMetricEngine) {
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
                throw Kit.Failure("pending interaction metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingInteractionMetricStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending interaction metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingInteractionMetricStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending interaction metric \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newPendingInteractionMetricWorkflow(_ store: any PendingInteractionMetricStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingInteractionMetricWorkflow {
        return PendingInteractionMetricWorkflow(
            store: store,
            validator: defaultPendingInteractionMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingInteractionMetricEngine(flags)
        )
    }
}
