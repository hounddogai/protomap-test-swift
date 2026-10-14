import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves regional isolation baselines through their life cycle and keeps a journal of what it did.
    final class RegionalIsolationBaselineWorkflow {
        var store: any RegionalIsolationBaselineStore
        var validator: RegionalIsolationBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalIsolationBaselineStore, validator: RegionalIsolationBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional isolation baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalIsolationBaselineStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional isolation baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalIsolationBaselineStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRegionalIsolationBaselineWorkflow(_ store: any RegionalIsolationBaselineStore, clock: any Kit.Clocks.Clock) -> RegionalIsolationBaselineWorkflow {
        return RegionalIsolationBaselineWorkflow(
            store: store,
            validator: defaultRegionalIsolationBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
