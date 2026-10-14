import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim rollups through their life cycle and keeps a journal of what it did.
    final class ClaimRollupWorkflow {
        var store: any ClaimRollupStore
        var validator: ClaimRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimRollupEngine

        init(store: any ClaimRollupStore, validator: ClaimRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimRollupEngine) {
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
                throw Kit.Failure("claim rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimRollupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim rollup \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newClaimRollupWorkflow(_ store: any ClaimRollupStore, clock: any Kit.Clocks.Clock) -> ClaimRollupWorkflow {
        return ClaimRollupWorkflow(
            store: store,
            validator: defaultClaimRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimRollupEngine()
        )
    }
}
