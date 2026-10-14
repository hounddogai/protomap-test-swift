import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves tiered task overrides through their life cycle and keeps a journal of what it did.
    final class TieredTaskOverrideCoordinator {
        var store: any TieredTaskOverrideStore
        var validator: TieredTaskOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredTaskOverrideEngine

        init(store: any TieredTaskOverrideStore, validator: TieredTaskOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredTaskOverrideEngine) {
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
                throw Kit.Failure("tiered task override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredTaskOverrideStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered task override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredTaskOverrideStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered task override \(code) not found")
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

    static func newTieredTaskOverrideCoordinator(_ store: any TieredTaskOverrideStore, clock: any Kit.Clocks.Clock) -> TieredTaskOverrideCoordinator {
        return TieredTaskOverrideCoordinator(
            store: store,
            validator: defaultTieredTaskOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredTaskOverrideEngine()
        )
    }
}
