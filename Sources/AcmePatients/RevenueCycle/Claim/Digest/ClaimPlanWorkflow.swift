import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim plans through their life cycle and keeps a journal of what it did.
    final class ClaimPlanCoordinator {
        var store: any ClaimPlanStore
        var validator: ClaimPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimPlanEngine

        init(store: any ClaimPlanStore, validator: ClaimPlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimPlanEngine) {
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
                throw Kit.Failure("claim plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimPlanStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimPlanStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim plan \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newClaimPlanCoordinator(_ store: any ClaimPlanStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClaimPlanCoordinator {
        return ClaimPlanCoordinator(
            store: store,
            validator: defaultClaimPlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimPlanEngine(flags)
        )
    }
}
