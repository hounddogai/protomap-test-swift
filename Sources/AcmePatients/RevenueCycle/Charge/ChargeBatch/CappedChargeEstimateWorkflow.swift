import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped charge estimates through their life cycle and keeps a journal of what it did.
    final class CappedChargeEstimateDesk {
        var store: any CappedChargeEstimateStore
        var validator: CappedChargeEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedChargeEstimateEngine

        init(store: any CappedChargeEstimateStore, validator: CappedChargeEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedChargeEstimateEngine) {
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
                throw Kit.Failure("capped charge estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedChargeEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped charge estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedChargeEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped charge estimate \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newCappedChargeEstimateDesk(_ store: any CappedChargeEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedChargeEstimateDesk {
        return CappedChargeEstimateDesk(
            store: store,
            validator: defaultCappedChargeEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedChargeEstimateEngine(flags)
        )
    }
}
