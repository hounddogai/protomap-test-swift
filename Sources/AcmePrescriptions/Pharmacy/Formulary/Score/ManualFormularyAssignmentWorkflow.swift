import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual formulary assignments through their life cycle and keeps a journal of what it did.
    final class ManualFormularyAssignmentCoordinator {
        var store: any ManualFormularyAssignmentStore
        var validator: ManualFormularyAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualFormularyAssignmentEngine

        init(store: any ManualFormularyAssignmentStore, validator: ManualFormularyAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualFormularyAssignmentEngine) {
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
                throw Kit.Failure("manual formulary assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualFormularyAssignmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual formulary assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualFormularyAssignmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual formulary assignment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newManualFormularyAssignmentCoordinator(_ store: any ManualFormularyAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualFormularyAssignmentCoordinator {
        return ManualFormularyAssignmentCoordinator(
            store: store,
            validator: defaultManualFormularyAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualFormularyAssignmentEngine(flags)
        )
    }
}
