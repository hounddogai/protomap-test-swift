import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves rolling denial entries through their life cycle and keeps a journal of what it did.
    final class RollingDenialEntryCoordinator {
        var store: any RollingDenialEntryStore
        var validator: RollingDenialEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingDenialEntryStore, validator: RollingDenialEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling denial entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingDenialEntryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling denial entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingDenialEntryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRollingDenialEntryCoordinator(_ store: any RollingDenialEntryStore, clock: any Kit.Clocks.Clock) -> RollingDenialEntryCoordinator {
        return RollingDenialEntryCoordinator(
            store: store,
            validator: defaultRollingDenialEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
