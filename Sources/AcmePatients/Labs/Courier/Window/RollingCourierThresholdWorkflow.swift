import AcmePlatform
import Foundation

extension Labs {
    /// Moves rolling courier thresholds through their life cycle and keeps a journal of what it did.
    final class RollingCourierThresholdService {
        var store: any RollingCourierThresholdStore
        var validator: RollingCourierThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingCourierThresholdStore, validator: RollingCourierThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling courier threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingCourierThresholdStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling courier threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingCourierThresholdStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newRollingCourierThresholdService(_ store: any RollingCourierThresholdStore, clock: any Kit.Clocks.Clock) -> RollingCourierThresholdService {
        return RollingCourierThresholdService(
            store: store,
            validator: defaultRollingCourierThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
