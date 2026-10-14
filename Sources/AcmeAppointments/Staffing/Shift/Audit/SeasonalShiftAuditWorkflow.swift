import AcmePlatform
import Foundation

extension Staffing {
    /// Moves seasonal shift audits through their life cycle and keeps a journal of what it did.
    final class SeasonalShiftAuditCoordinator {
        var store: any SeasonalShiftAuditStore
        var validator: SeasonalShiftAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalShiftAuditEngine

        init(store: any SeasonalShiftAuditStore, validator: SeasonalShiftAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalShiftAuditEngine) {
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
                throw Kit.Failure("seasonal shift audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalShiftAuditStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal shift audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalShiftAuditStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal shift audit \(code) not found")
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

    static func newSeasonalShiftAuditCoordinator(_ store: any SeasonalShiftAuditStore, clock: any Kit.Clocks.Clock) -> SeasonalShiftAuditCoordinator {
        return SeasonalShiftAuditCoordinator(
            store: store,
            validator: defaultSeasonalShiftAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalShiftAuditEngine()
        )
    }
}
