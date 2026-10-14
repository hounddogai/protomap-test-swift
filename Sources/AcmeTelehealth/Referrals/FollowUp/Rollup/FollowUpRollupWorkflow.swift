import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up rollups through their life cycle and keeps a journal of what it did.
    final class FollowUpRollupCoordinator {
        var store: any FollowUpRollupStore
        var validator: FollowUpRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpRollupStore, validator: FollowUpRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpRollupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpRollupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newFollowUpRollupCoordinator(_ store: any FollowUpRollupStore, clock: any Kit.Clocks.Clock) -> FollowUpRollupCoordinator {
        return FollowUpRollupCoordinator(
            store: store,
            validator: defaultFollowUpRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
