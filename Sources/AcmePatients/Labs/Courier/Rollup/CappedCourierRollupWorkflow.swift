import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped courier rollups through their life cycle and keeps a journal of what it did.
    final class CappedCourierRollupWorkflow {
        var store: any CappedCourierRollupStore
        var validator: CappedCourierRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedCourierRollupEngine

        init(store: any CappedCourierRollupStore, validator: CappedCourierRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedCourierRollupEngine) {
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
                throw Kit.Failure("capped courier rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCourierRollupStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped courier rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCourierRollupStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped courier rollup \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCappedCourierRollupWorkflow(_ store: any CappedCourierRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedCourierRollupWorkflow {
        return CappedCourierRollupWorkflow(
            store: store,
            validator: defaultCappedCourierRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedCourierRollupEngine(flags)
        )
    }
}
