import AcmePlatform
import Foundation

extension Referrals {
    /// Moves manual network milestones through their life cycle and keeps a journal of what it did.
    final class ManualNetworkMilestoneDesk {
        var store: any ManualNetworkMilestoneStore
        var validator: ManualNetworkMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualNetworkMilestoneEngine

        init(store: any ManualNetworkMilestoneStore, validator: ManualNetworkMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualNetworkMilestoneEngine) {
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
                throw Kit.Failure("manual network milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualNetworkMilestoneStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualNetworkMilestoneStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network milestone \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newManualNetworkMilestoneDesk(_ store: any ManualNetworkMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualNetworkMilestoneDesk {
        return ManualNetworkMilestoneDesk(
            store: store,
            validator: defaultManualNetworkMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualNetworkMilestoneEngine(flags)
        )
    }
}
