import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding thresholds through their life cycle and keeps a journal of what it did.
    final class RoundingThresholdWorkflow {
        var store: any RoundingThresholdStore
        var validator: RoundingThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RoundingThresholdStore, validator: RoundingThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rounding threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingThresholdStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingThresholdStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newRoundingThresholdWorkflow(_ store: any RoundingThresholdStore, clock: any Kit.Clocks.Clock) -> RoundingThresholdWorkflow {
        return RoundingThresholdWorkflow(
            store: store,
            validator: defaultRoundingThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
