import AcmePlatform
import Foundation

extension Referrals {
    /// Moves rolling slot checkpoints through their life cycle and keeps a journal of what it did.
    final class RollingSlotCheckpointService {
        var store: any RollingSlotCheckpointStore
        var validator: RollingSlotCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingSlotCheckpointStore, validator: RollingSlotCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling slot checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingSlotCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling slot checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingSlotCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRollingSlotCheckpointService(_ store: any RollingSlotCheckpointStore, clock: any Kit.Clocks.Clock) -> RollingSlotCheckpointService {
        return RollingSlotCheckpointService(
            store: store,
            validator: defaultRollingSlotCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
