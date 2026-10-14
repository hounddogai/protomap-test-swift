import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped discharge plan items through their life cycle and keeps a journal of what it did.
    final class CappedDischargePlanItemDesk {
        var store: any CappedDischargePlanItemStore
        var validator: CappedDischargePlanItemValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedDischargePlanItemEngine

        init(store: any CappedDischargePlanItemStore, validator: CappedDischargePlanItemValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedDischargePlanItemEngine) {
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
                throw Kit.Failure("capped discharge plan item \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedDischargePlanItemStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped discharge plan item \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedDischargePlanItemStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped discharge plan item \(code) not found")
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

    static func newCappedDischargePlanItemDesk(_ store: any CappedDischargePlanItemStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedDischargePlanItemDesk {
        return CappedDischargePlanItemDesk(
            store: store,
            validator: defaultCappedDischargePlanItemValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedDischargePlanItemEngine(flags)
        )
    }
}
