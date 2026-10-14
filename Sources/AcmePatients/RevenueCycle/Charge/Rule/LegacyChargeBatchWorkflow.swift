import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves legacy charge batches through their life cycle and keeps a journal of what it did.
    final class LegacyChargeBatchWorkflow {
        var store: any LegacyChargeBatchStore
        var validator: LegacyChargeBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyChargeBatchStore, validator: LegacyChargeBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy charge batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyChargeBatchStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy charge batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyChargeBatchStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLegacyChargeBatchWorkflow(_ store: any LegacyChargeBatchStore, clock: any Kit.Clocks.Clock) -> LegacyChargeBatchWorkflow {
        return LegacyChargeBatchWorkflow(
            store: store,
            validator: defaultLegacyChargeBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
