import AcmePlatform
import Foundation

extension Staffing {
    /// Moves capped overtime rollups through their life cycle and keeps a journal of what it did.
    final class CappedOvertimeRollupDesk {
        var store: any CappedOvertimeRollupStore
        var validator: CappedOvertimeRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedOvertimeRollupEngine

        init(store: any CappedOvertimeRollupStore, validator: CappedOvertimeRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedOvertimeRollupEngine) {
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
                throw Kit.Failure("capped overtime rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedOvertimeRollupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped overtime rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedOvertimeRollupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped overtime rollup \(code) not found")
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

    static func newCappedOvertimeRollupDesk(_ store: any CappedOvertimeRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedOvertimeRollupDesk {
        return CappedOvertimeRollupDesk(
            store: store,
            validator: defaultCappedOvertimeRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedOvertimeRollupEngine(flags)
        )
    }
}
