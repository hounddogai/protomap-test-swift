import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up allocations through their life cycle and keeps a journal of what it did.
    final class FollowUpAllocationManager {
        var store: any FollowUpAllocationStore
        var validator: FollowUpAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FollowUpAllocationStore, validator: FollowUpAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpAllocationStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpAllocationStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFollowUpAllocationManager(_ store: any FollowUpAllocationStore, clock: any Kit.Clocks.Clock) -> FollowUpAllocationManager {
        return FollowUpAllocationManager(
            store: store,
            validator: defaultFollowUpAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
