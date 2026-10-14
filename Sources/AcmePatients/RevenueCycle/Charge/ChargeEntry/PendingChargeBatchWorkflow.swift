import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending charge batches through their life cycle and keeps a journal of what it did.
    final class PendingChargeBatchWorkflow {
        var store: any PendingChargeBatchStore
        var validator: PendingChargeBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingChargeBatchEngine

        init(store: any PendingChargeBatchStore, validator: PendingChargeBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingChargeBatchEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending charge batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingChargeBatchStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending charge batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingChargeBatchStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending charge batch \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPendingChargeBatchWorkflow(_ store: any PendingChargeBatchStore, clock: any Kit.Clocks.Clock) -> PendingChargeBatchWorkflow {
        return PendingChargeBatchWorkflow(
            store: store,
            validator: defaultPendingChargeBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingChargeBatchEngine()
        )
    }
}
