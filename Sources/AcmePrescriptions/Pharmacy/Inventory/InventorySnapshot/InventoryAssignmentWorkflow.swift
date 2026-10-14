import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves inventory assignments through their life cycle and keeps a journal of what it did.
    final class InventoryAssignmentCoordinator {
        var store: any InventoryAssignmentStore
        var validator: InventoryAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InventoryAssignmentEngine

        init(store: any InventoryAssignmentStore, validator: InventoryAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InventoryAssignmentEngine) {
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
                throw Kit.Failure("inventory assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InventoryAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InventoryAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("inventory assignment \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newInventoryAssignmentCoordinator(_ store: any InventoryAssignmentStore, clock: any Kit.Clocks.Clock) -> InventoryAssignmentCoordinator {
        return InventoryAssignmentCoordinator(
            store: store,
            validator: defaultInventoryAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultInventoryAssignmentEngine()
        )
    }
}
