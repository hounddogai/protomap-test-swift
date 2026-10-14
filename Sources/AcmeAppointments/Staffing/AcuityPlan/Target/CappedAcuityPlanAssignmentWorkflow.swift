import AcmePlatform
import Foundation

extension Staffing {
    /// Moves capped acuity plan assignments through their life cycle and keeps a journal of what it did.
    final class CappedAcuityPlanAssignmentCoordinator {
        var store: any CappedAcuityPlanAssignmentStore
        var validator: CappedAcuityPlanAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedAcuityPlanAssignmentEngine

        init(store: any CappedAcuityPlanAssignmentStore, validator: CappedAcuityPlanAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedAcuityPlanAssignmentEngine) {
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
                throw Kit.Failure("capped acuity plan assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedAcuityPlanAssignmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped acuity plan assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedAcuityPlanAssignmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped acuity plan assignment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCappedAcuityPlanAssignmentCoordinator(_ store: any CappedAcuityPlanAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedAcuityPlanAssignmentCoordinator {
        return CappedAcuityPlanAssignmentCoordinator(
            store: store,
            validator: defaultCappedAcuityPlanAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedAcuityPlanAssignmentEngine(flags)
        )
    }
}
