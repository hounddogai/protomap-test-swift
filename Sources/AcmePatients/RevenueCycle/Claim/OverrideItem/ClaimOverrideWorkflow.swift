import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim overrides through their life cycle and keeps a journal of what it did.
    final class ClaimOverrideCoordinator {
        var store: any ClaimOverrideStore
        var validator: ClaimOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ClaimOverrideStore, validator: ClaimOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("claim override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimOverrideStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimOverrideStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newClaimOverrideCoordinator(_ store: any ClaimOverrideStore, clock: any Kit.Clocks.Clock) -> ClaimOverrideCoordinator {
        return ClaimOverrideCoordinator(
            store: store,
            validator: defaultClaimOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
