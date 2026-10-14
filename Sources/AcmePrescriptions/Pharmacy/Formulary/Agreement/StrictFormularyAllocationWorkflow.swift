import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves strict formulary allocations through their life cycle and keeps a journal of what it did.
    final class StrictFormularyAllocationManager {
        var store: any StrictFormularyAllocationStore
        var validator: StrictFormularyAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictFormularyAllocationStore, validator: StrictFormularyAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict formulary allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictFormularyAllocationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict formulary allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictFormularyAllocationStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newStrictFormularyAllocationManager(_ store: any StrictFormularyAllocationStore, clock: any Kit.Clocks.Clock) -> StrictFormularyAllocationManager {
        return StrictFormularyAllocationManager(
            store: store,
            validator: defaultStrictFormularyAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
