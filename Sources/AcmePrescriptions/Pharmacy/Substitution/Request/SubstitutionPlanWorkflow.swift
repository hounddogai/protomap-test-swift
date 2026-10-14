import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution plans through their life cycle and keeps a journal of what it did.
    final class SubstitutionPlanManager {
        var store: any SubstitutionPlanStore
        var validator: SubstitutionPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionPlanEngine

        init(store: any SubstitutionPlanStore, validator: SubstitutionPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionPlanEngine) {
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
                throw Kit.Failure("substitution plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionPlanStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionPlanStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution plan \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newSubstitutionPlanManager(_ store: any SubstitutionPlanStore, clock: any Kit.Clocks.Clock) -> SubstitutionPlanManager {
        return SubstitutionPlanManager(
            store: store,
            validator: defaultSubstitutionPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionPlanEngine()
        )
    }
}
