import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves pending formulary allocations through their life cycle and keeps a journal of what it did.
    final class PendingFormularyAllocationCoordinator {
        var store: any PendingFormularyAllocationStore
        var validator: PendingFormularyAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingFormularyAllocationEngine

        init(store: any PendingFormularyAllocationStore, validator: PendingFormularyAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingFormularyAllocationEngine) {
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
                throw Kit.Failure("pending formulary allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingFormularyAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending formulary allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingFormularyAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending formulary allocation \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newPendingFormularyAllocationCoordinator(_ store: any PendingFormularyAllocationStore, clock: any Kit.Clocks.Clock) -> PendingFormularyAllocationCoordinator {
        return PendingFormularyAllocationCoordinator(
            store: store,
            validator: defaultPendingFormularyAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingFormularyAllocationEngine()
        )
    }
}
