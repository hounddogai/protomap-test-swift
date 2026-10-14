import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves strict claim digests through their life cycle and keeps a journal of what it did.
    final class StrictClaimDigestWorkflow {
        var store: any StrictClaimDigestStore
        var validator: StrictClaimDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictClaimDigestEngine

        init(store: any StrictClaimDigestStore, validator: StrictClaimDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictClaimDigestEngine) {
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
                throw Kit.Failure("strict claim digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictClaimDigestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict claim digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictClaimDigestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict claim digest \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newStrictClaimDigestWorkflow(_ store: any StrictClaimDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictClaimDigestWorkflow {
        return StrictClaimDigestWorkflow(
            store: store,
            validator: defaultStrictClaimDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictClaimDigestEngine(flags)
        )
    }
}
