import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves regional authorization allocations through their life cycle and keeps a journal of what it did.
    final class RegionalAuthorizationAllocationWorkflow {
        var store: any RegionalAuthorizationAllocationStore
        var validator: RegionalAuthorizationAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalAuthorizationAllocationStore, validator: RegionalAuthorizationAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional authorization allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalAuthorizationAllocationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional authorization allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalAuthorizationAllocationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRegionalAuthorizationAllocationWorkflow(_ store: any RegionalAuthorizationAllocationStore, clock: any Kit.Clocks.Clock) -> RegionalAuthorizationAllocationWorkflow {
        return RegionalAuthorizationAllocationWorkflow(
            store: store,
            validator: defaultRegionalAuthorizationAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
