import AcmePlatform
import Foundation

extension Referrals {
    /// Moves pending follow up adjustments through their life cycle and keeps a journal of what it did.
    final class PendingFollowUpAdjustmentCoordinator {
        var store: any PendingFollowUpAdjustmentStore
        var validator: PendingFollowUpAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingFollowUpAdjustmentEngine

        init(store: any PendingFollowUpAdjustmentStore, validator: PendingFollowUpAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingFollowUpAdjustmentEngine) {
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
                throw Kit.Failure("pending follow up adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingFollowUpAdjustmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending follow up adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingFollowUpAdjustmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending follow up adjustment \(code) not found")
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

    static func newPendingFollowUpAdjustmentCoordinator(_ store: any PendingFollowUpAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingFollowUpAdjustmentCoordinator {
        return PendingFollowUpAdjustmentCoordinator(
            store: store,
            validator: defaultPendingFollowUpAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingFollowUpAdjustmentEngine(flags)
        )
    }
}
