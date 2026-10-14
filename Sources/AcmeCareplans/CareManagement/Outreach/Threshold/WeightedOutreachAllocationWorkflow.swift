import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves weighted outreach allocations through their life cycle and keeps a journal of what it did.
    final class WeightedOutreachAllocationManager {
        var store: any WeightedOutreachAllocationStore
        var validator: WeightedOutreachAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedOutreachAllocationEngine

        init(store: any WeightedOutreachAllocationStore, validator: WeightedOutreachAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedOutreachAllocationEngine) {
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
                throw Kit.Failure("weighted outreach allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedOutreachAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted outreach allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedOutreachAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted outreach allocation \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newWeightedOutreachAllocationManager(_ store: any WeightedOutreachAllocationStore, clock: any Kit.Clocks.Clock) -> WeightedOutreachAllocationManager {
        return WeightedOutreachAllocationManager(
            store: store,
            validator: defaultWeightedOutreachAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedOutreachAllocationEngine()
        )
    }
}
