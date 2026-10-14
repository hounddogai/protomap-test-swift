import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending denial overrides through their life cycle and keeps a journal of what it did.
    final class PendingDenialOverrideWorkflow {
        var store: any PendingDenialOverrideStore
        var validator: PendingDenialOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingDenialOverrideEngine

        init(store: any PendingDenialOverrideStore, validator: PendingDenialOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingDenialOverrideEngine) {
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
                throw Kit.Failure("pending denial override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingDenialOverrideStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending denial override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingDenialOverrideStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending denial override \(code) not found")
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

    static func newPendingDenialOverrideWorkflow(_ store: any PendingDenialOverrideStore, clock: any Kit.Clocks.Clock) -> PendingDenialOverrideWorkflow {
        return PendingDenialOverrideWorkflow(
            store: store,
            validator: defaultPendingDenialOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingDenialOverrideEngine()
        )
    }
}
