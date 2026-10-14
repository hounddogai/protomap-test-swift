import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves manual authorization rollups through their life cycle and keeps a journal of what it did.
    final class ManualAuthorizationRollupManager {
        var store: any ManualAuthorizationRollupStore
        var validator: ManualAuthorizationRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualAuthorizationRollupEngine

        init(store: any ManualAuthorizationRollupStore, validator: ManualAuthorizationRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualAuthorizationRollupEngine) {
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
                throw Kit.Failure("manual authorization rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualAuthorizationRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual authorization rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualAuthorizationRollupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual authorization rollup \(code) not found")
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

    static func newManualAuthorizationRollupManager(_ store: any ManualAuthorizationRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualAuthorizationRollupManager {
        return ManualAuthorizationRollupManager(
            store: store,
            validator: defaultManualAuthorizationRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualAuthorizationRollupEngine(flags)
        )
    }
}
