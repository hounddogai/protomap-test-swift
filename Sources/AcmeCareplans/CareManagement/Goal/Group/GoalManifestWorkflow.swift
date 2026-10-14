import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves goal manifests through their life cycle and keeps a journal of what it did.
    final class GoalManifestManager {
        var store: any GoalManifestStore
        var validator: GoalManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GoalManifestEngine

        init(store: any GoalManifestStore, validator: GoalManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GoalManifestEngine) {
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
                throw Kit.Failure("goal manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GoalManifestStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GoalManifestStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("goal manifest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newGoalManifestManager(_ store: any GoalManifestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GoalManifestManager {
        return GoalManifestManager(
            store: store,
            validator: defaultGoalManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultGoalManifestEngine(flags)
        )
    }
}
