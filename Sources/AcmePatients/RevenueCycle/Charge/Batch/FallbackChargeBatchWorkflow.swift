import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback charge batches through their life cycle and keeps a journal of what it did.
    final class FallbackChargeBatchDesk {
        var store: any FallbackChargeBatchStore
        var validator: FallbackChargeBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackChargeBatchEngine

        init(store: any FallbackChargeBatchStore, validator: FallbackChargeBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackChargeBatchEngine) {
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
                throw Kit.Failure("fallback charge batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackChargeBatchStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback charge batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackChargeBatchStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback charge batch \(code) not found")
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

    static func newFallbackChargeBatchDesk(_ store: any FallbackChargeBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackChargeBatchDesk {
        return FallbackChargeBatchDesk(
            store: store,
            validator: defaultFallbackChargeBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackChargeBatchEngine(flags)
        )
    }
}
