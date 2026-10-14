import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves regional outreach allocations through their life cycle and keeps a journal of what it did.
    final class RegionalOutreachAllocationWorkflow {
        var store: any RegionalOutreachAllocationStore
        var validator: RegionalOutreachAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalOutreachAllocationEngine

        init(store: any RegionalOutreachAllocationStore, validator: RegionalOutreachAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalOutreachAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional outreach allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalOutreachAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional outreach allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalOutreachAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional outreach allocation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRegionalOutreachAllocationWorkflow(_ store: any RegionalOutreachAllocationStore, clock: any Kit.Clocks.Clock) -> RegionalOutreachAllocationWorkflow {
        return RegionalOutreachAllocationWorkflow(
            store: store,
            validator: defaultRegionalOutreachAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalOutreachAllocationEngine()
        )
    }
}
