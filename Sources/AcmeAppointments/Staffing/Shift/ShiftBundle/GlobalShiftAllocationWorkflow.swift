import AcmePlatform
import Foundation

extension Staffing {
    /// Moves global shift allocations through their life cycle and keeps a journal of what it did.
    final class GlobalShiftAllocationManager {
        var store: any GlobalShiftAllocationStore
        var validator: GlobalShiftAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalShiftAllocationEngine

        init(store: any GlobalShiftAllocationStore, validator: GlobalShiftAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalShiftAllocationEngine) {
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
                throw Kit.Failure("global shift allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalShiftAllocationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global shift allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalShiftAllocationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global shift allocation \(code) not found")
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

    static func newGlobalShiftAllocationManager(_ store: any GlobalShiftAllocationStore, clock: any Kit.Clocks.Clock) -> GlobalShiftAllocationManager {
        return GlobalShiftAllocationManager(
            store: store,
            validator: defaultGlobalShiftAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalShiftAllocationEngine()
        )
    }
}
