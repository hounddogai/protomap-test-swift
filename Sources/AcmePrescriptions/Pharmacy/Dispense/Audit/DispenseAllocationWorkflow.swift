import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense allocations through their life cycle and keeps a journal of what it did.
    final class DispenseAllocationManager {
        var store: any DispenseAllocationStore
        var validator: DispenseAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispenseAllocationEngine

        init(store: any DispenseAllocationStore, validator: DispenseAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispenseAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense allocation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newDispenseAllocationManager(_ store: any DispenseAllocationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DispenseAllocationManager {
        return DispenseAllocationManager(
            store: store,
            validator: defaultDispenseAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispenseAllocationEngine(flags)
        )
    }
}
