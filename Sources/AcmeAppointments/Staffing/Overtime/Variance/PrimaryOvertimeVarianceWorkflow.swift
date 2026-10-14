import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary overtime variances through their life cycle and keeps a journal of what it did.
    final class PrimaryOvertimeVarianceWorkflow {
        var store: any PrimaryOvertimeVarianceStore
        var validator: PrimaryOvertimeVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryOvertimeVarianceEngine

        init(store: any PrimaryOvertimeVarianceStore, validator: PrimaryOvertimeVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryOvertimeVarianceEngine) {
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
                throw Kit.Failure("primary overtime variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryOvertimeVarianceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary overtime variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryOvertimeVarianceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary overtime variance \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newPrimaryOvertimeVarianceWorkflow(_ store: any PrimaryOvertimeVarianceStore, clock: any Kit.Clocks.Clock) -> PrimaryOvertimeVarianceWorkflow {
        return PrimaryOvertimeVarianceWorkflow(
            store: store,
            validator: defaultPrimaryOvertimeVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryOvertimeVarianceEngine()
        )
    }
}
