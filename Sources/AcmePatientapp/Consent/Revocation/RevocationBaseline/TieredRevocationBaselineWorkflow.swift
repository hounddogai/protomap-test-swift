import AcmePlatform
import Foundation

extension Consent {
    /// Moves tiered revocation baselines through their life cycle and keeps a journal of what it did.
    final class TieredRevocationBaselineCoordinator {
        var store: any TieredRevocationBaselineStore
        var validator: TieredRevocationBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredRevocationBaselineEngine

        init(store: any TieredRevocationBaselineStore, validator: TieredRevocationBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredRevocationBaselineEngine) {
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
                throw Kit.Failure("tiered revocation baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRevocationBaselineStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered revocation baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRevocationBaselineStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered revocation baseline \(code) not found")
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

    static func newTieredRevocationBaselineCoordinator(_ store: any TieredRevocationBaselineStore, clock: any Kit.Clocks.Clock) -> TieredRevocationBaselineCoordinator {
        return TieredRevocationBaselineCoordinator(
            store: store,
            validator: defaultTieredRevocationBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredRevocationBaselineEngine()
        )
    }
}
