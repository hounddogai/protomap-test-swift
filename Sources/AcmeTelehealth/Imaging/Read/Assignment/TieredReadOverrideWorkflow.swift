import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered read overrides through their life cycle and keeps a journal of what it did.
    final class TieredReadOverrideCoordinator {
        var store: any TieredReadOverrideStore
        var validator: TieredReadOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredReadOverrideEngine

        init(store: any TieredReadOverrideStore, validator: TieredReadOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredReadOverrideEngine) {
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
                throw Kit.Failure("tiered read override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredReadOverrideStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered read override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredReadOverrideStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered read override \(code) not found")
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

    static func newTieredReadOverrideCoordinator(_ store: any TieredReadOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredReadOverrideCoordinator {
        return TieredReadOverrideCoordinator(
            store: store,
            validator: defaultTieredReadOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredReadOverrideEngine(flags)
        )
    }
}
