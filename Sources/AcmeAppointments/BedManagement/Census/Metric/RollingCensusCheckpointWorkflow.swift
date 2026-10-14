import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves rolling census checkpoints through their life cycle and keeps a journal of what it did.
    final class RollingCensusCheckpointService {
        var store: any RollingCensusCheckpointStore
        var validator: RollingCensusCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingCensusCheckpointStore, validator: RollingCensusCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling census checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingCensusCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling census checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingCensusCheckpointStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRollingCensusCheckpointService(_ store: any RollingCensusCheckpointStore, clock: any Kit.Clocks.Clock) -> RollingCensusCheckpointService {
        return RollingCensusCheckpointService(
            store: store,
            validator: defaultRollingCensusCheckpointValidator(),
            clock: clock,
            journal: []
        )
    }
}
