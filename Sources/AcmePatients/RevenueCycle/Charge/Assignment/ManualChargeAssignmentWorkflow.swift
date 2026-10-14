import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves manual charge assignments through their life cycle and keeps a journal of what it did.
    final class ManualChargeAssignmentWorkflow {
        var store: any ManualChargeAssignmentStore
        var validator: ManualChargeAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualChargeAssignmentEngine

        init(store: any ManualChargeAssignmentStore, validator: ManualChargeAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualChargeAssignmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual charge assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualChargeAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual charge assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualChargeAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual charge assignment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newManualChargeAssignmentWorkflow(_ store: any ManualChargeAssignmentStore, clock: any Kit.Clocks.Clock) -> ManualChargeAssignmentWorkflow {
        return ManualChargeAssignmentWorkflow(
            store: store,
            validator: defaultManualChargeAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualChargeAssignmentEngine()
        )
    }
}
