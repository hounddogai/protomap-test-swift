import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves seasonal remittance assignments through their life cycle and keeps a journal of what it did.
    final class SeasonalRemittanceAssignmentCoordinator {
        var store: any SeasonalRemittanceAssignmentStore
        var validator: SeasonalRemittanceAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalRemittanceAssignmentEngine

        init(store: any SeasonalRemittanceAssignmentStore, validator: SeasonalRemittanceAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalRemittanceAssignmentEngine) {
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
                throw Kit.Failure("seasonal remittance assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalRemittanceAssignmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal remittance assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalRemittanceAssignmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal remittance assignment \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newSeasonalRemittanceAssignmentCoordinator(_ store: any SeasonalRemittanceAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalRemittanceAssignmentCoordinator {
        return SeasonalRemittanceAssignmentCoordinator(
            store: store,
            validator: defaultSeasonalRemittanceAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalRemittanceAssignmentEngine(flags)
        )
    }
}
