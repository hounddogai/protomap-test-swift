import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift allocations through their life cycle and keeps a journal of what it did.
    final class ShiftAllocationCoordinator {
        var store: any ShiftAllocationStore
        var validator: ShiftAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftAllocationEngine

        init(store: any ShiftAllocationStore, validator: ShiftAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftAllocationEngine) {
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
                throw Kit.Failure("shift allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift allocation \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newShiftAllocationCoordinator(_ store: any ShiftAllocationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftAllocationCoordinator {
        return ShiftAllocationCoordinator(
            store: store,
            validator: defaultShiftAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftAllocationEngine(flags)
        )
    }
}
