import AcmePlatform
import Foundation

extension Labs {
    /// Moves rolling panel quotas through their life cycle and keeps a journal of what it did.
    final class RollingPanelQuotaManager {
        var store: any RollingPanelQuotaStore
        var validator: RollingPanelQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingPanelQuotaEngine

        init(store: any RollingPanelQuotaStore, validator: RollingPanelQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingPanelQuotaEngine) {
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
                throw Kit.Failure("rolling panel quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingPanelQuotaStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling panel quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingPanelQuotaStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling panel quota \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRollingPanelQuotaManager(_ store: any RollingPanelQuotaStore, clock: any Kit.Clocks.Clock) -> RollingPanelQuotaManager {
        return RollingPanelQuotaManager(
            store: store,
            validator: defaultRollingPanelQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingPanelQuotaEngine()
        )
    }
}
