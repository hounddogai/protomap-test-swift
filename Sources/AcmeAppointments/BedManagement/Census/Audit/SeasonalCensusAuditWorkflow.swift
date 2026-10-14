import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves seasonal census audits through their life cycle and keeps a journal of what it did.
    final class SeasonalCensusAuditWorkflow {
        var store: any SeasonalCensusAuditStore
        var validator: SeasonalCensusAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalCensusAuditStore, validator: SeasonalCensusAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal census audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCensusAuditStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal census audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCensusAuditStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newSeasonalCensusAuditWorkflow(_ store: any SeasonalCensusAuditStore, clock: any Kit.Clocks.Clock) -> SeasonalCensusAuditWorkflow {
        return SeasonalCensusAuditWorkflow(
            store: store,
            validator: defaultSeasonalCensusAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
