import AcmePlatform
import Foundation

extension Staffing {
    /// Moves regional float pool variances through their life cycle and keeps a journal of what it did.
    final class RegionalFloatPoolVarianceManager {
        var store: any RegionalFloatPoolVarianceStore
        var validator: RegionalFloatPoolVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalFloatPoolVarianceEngine

        init(store: any RegionalFloatPoolVarianceStore, validator: RegionalFloatPoolVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalFloatPoolVarianceEngine) {
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
                throw Kit.Failure("regional float pool variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalFloatPoolVarianceStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional float pool variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalFloatPoolVarianceStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional float pool variance \(code) not found")
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

    static func newRegionalFloatPoolVarianceManager(_ store: any RegionalFloatPoolVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalFloatPoolVarianceManager {
        return RegionalFloatPoolVarianceManager(
            store: store,
            validator: defaultRegionalFloatPoolVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalFloatPoolVarianceEngine(flags)
        )
    }
}
