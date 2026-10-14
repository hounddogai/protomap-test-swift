import AcmePlatform
import Foundation

extension Imaging {
    /// Moves primary priority thresholds through their life cycle and keeps a journal of what it did.
    final class PrimaryPriorityThresholdWorkflow {
        var store: any PrimaryPriorityThresholdStore
        var validator: PrimaryPriorityThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryPriorityThresholdStore, validator: PrimaryPriorityThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary priority threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryPriorityThresholdStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary priority threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryPriorityThresholdStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPrimaryPriorityThresholdWorkflow(_ store: any PrimaryPriorityThresholdStore, clock: any Kit.Clocks.Clock) -> PrimaryPriorityThresholdWorkflow {
        return PrimaryPriorityThresholdWorkflow(
            store: store,
            validator: defaultPrimaryPriorityThresholdValidator(),
            clock: clock,
            journal: []
        )
    }
}
