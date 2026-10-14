import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves global cleaning plans through their life cycle and keeps a journal of what it did.
    final class GlobalCleaningPlanService {
        var store: any GlobalCleaningPlanStore
        var validator: GlobalCleaningPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalCleaningPlanEngine

        init(store: any GlobalCleaningPlanStore, validator: GlobalCleaningPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalCleaningPlanEngine) {
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
                throw Kit.Failure("global cleaning plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalCleaningPlanStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global cleaning plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalCleaningPlanStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global cleaning plan \(code) not found")
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

    static func newGlobalCleaningPlanService(_ store: any GlobalCleaningPlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalCleaningPlanService {
        return GlobalCleaningPlanService(
            store: store,
            validator: defaultGlobalCleaningPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalCleaningPlanEngine(flags)
        )
    }
}
