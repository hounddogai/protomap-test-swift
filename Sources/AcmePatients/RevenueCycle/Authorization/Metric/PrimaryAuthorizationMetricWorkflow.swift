import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves primary authorization metrics through their life cycle and keeps a journal of what it did.
    final class PrimaryAuthorizationMetricCoordinator {
        var store: any PrimaryAuthorizationMetricStore
        var validator: PrimaryAuthorizationMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryAuthorizationMetricStore, validator: PrimaryAuthorizationMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary authorization metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAuthorizationMetricStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary authorization metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAuthorizationMetricStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newPrimaryAuthorizationMetricCoordinator(_ store: any PrimaryAuthorizationMetricStore, clock: any Kit.Clocks.Clock) -> PrimaryAuthorizationMetricCoordinator {
        return PrimaryAuthorizationMetricCoordinator(
            store: store,
            validator: defaultPrimaryAuthorizationMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
