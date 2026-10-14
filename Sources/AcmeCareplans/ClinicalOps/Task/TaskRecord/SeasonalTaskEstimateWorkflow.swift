import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves seasonal task estimates through their life cycle and keeps a journal of what it did.
    final class SeasonalTaskEstimateWorkflow {
        var store: any SeasonalTaskEstimateStore
        var validator: SeasonalTaskEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalTaskEstimateStore, validator: SeasonalTaskEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("seasonal task estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalTaskEstimateStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal task estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalTaskEstimateStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newSeasonalTaskEstimateWorkflow(_ store: any SeasonalTaskEstimateStore, clock: any Kit.Clocks.Clock) -> SeasonalTaskEstimateWorkflow {
        return SeasonalTaskEstimateWorkflow(
            store: store,
            validator: defaultSeasonalTaskEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
