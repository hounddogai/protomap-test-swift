import AcmePlatform
import Foundation

extension Consent {
    /// Moves tiered proxy milestones through their life cycle and keeps a journal of what it did.
    final class TieredProxyMilestoneManager {
        var store: any TieredProxyMilestoneStore
        var validator: TieredProxyMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredProxyMilestoneEngine

        init(store: any TieredProxyMilestoneStore, validator: TieredProxyMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredProxyMilestoneEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered proxy milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredProxyMilestoneStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered proxy milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredProxyMilestoneStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered proxy milestone \(code) not found")
            }
            let result = engine.run(item)
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

    static func newTieredProxyMilestoneManager(_ store: any TieredProxyMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredProxyMilestoneManager {
        return TieredProxyMilestoneManager(
            store: store,
            validator: defaultTieredProxyMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredProxyMilestoneEngine(flags)
        )
    }
}
