import AcmePlatform
import Foundation

extension Referrals {
    /// Moves tiered closure milestones through their life cycle and keeps a journal of what it did.
    final class TieredClosureMilestoneDesk {
        var store: any TieredClosureMilestoneStore
        var validator: TieredClosureMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredClosureMilestoneEngine

        init(store: any TieredClosureMilestoneStore, validator: TieredClosureMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredClosureMilestoneEngine) {
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
                throw Kit.Failure("tiered closure milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredClosureMilestoneStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered closure milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredClosureMilestoneStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered closure milestone \(code) not found")
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

    static func newTieredClosureMilestoneDesk(_ store: any TieredClosureMilestoneStore, clock: any Kit.Clocks.Clock) -> TieredClosureMilestoneDesk {
        return TieredClosureMilestoneDesk(
            store: store,
            validator: defaultTieredClosureMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredClosureMilestoneEngine()
        )
    }
}
