import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped discharge plan thresholds through their life cycle and keeps a journal of what it did.
    final class CappedDischargePlanThresholdService {
        var store: any CappedDischargePlanThresholdStore
        var validator: CappedDischargePlanThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedDischargePlanThresholdStore, validator: CappedDischargePlanThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped discharge plan threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedDischargePlanThresholdStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped discharge plan threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedDischargePlanThresholdStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newCappedDischargePlanThresholdService(_ store: any CappedDischargePlanThresholdStore, clock: any Kit.Clocks.Clock) -> CappedDischargePlanThresholdService {
        return CappedDischargePlanThresholdService(
            store: store,
            validator: defaultCappedDischargePlanThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
