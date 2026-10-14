import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance assignments through their life cycle and keeps a journal of what it did.
    final class RemittanceAssignmentWorkflow {
        var store: any RemittanceAssignmentStore
        var validator: RemittanceAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceAssignmentEngine

        init(store: any RemittanceAssignmentStore, validator: RemittanceAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceAssignmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceAssignmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceAssignmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance assignment \(code) not found")
            }
            let result = engine.price(item)
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

    static func newRemittanceAssignmentWorkflow(_ store: any RemittanceAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceAssignmentWorkflow {
        return RemittanceAssignmentWorkflow(
            store: store,
            validator: defaultRemittanceAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceAssignmentEngine(flags)
        )
    }
}
