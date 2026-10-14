import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan tiers through their life cycle and keeps a journal of what it did.
    final class AcuityPlanTierService {
        var store: any AcuityPlanTierStore
        var validator: AcuityPlanTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanTierEngine

        init(store: any AcuityPlanTierStore, validator: AcuityPlanTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanTierEngine) {
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
                throw Kit.Failure("acuity plan tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanTierStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanTierStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan tier \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newAcuityPlanTierService(_ store: any AcuityPlanTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AcuityPlanTierService {
        return AcuityPlanTierService(
            store: store,
            validator: defaultAcuityPlanTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanTierEngine(flags)
        )
    }
}
