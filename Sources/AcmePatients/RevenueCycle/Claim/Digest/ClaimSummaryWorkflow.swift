import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim summaries through their life cycle and keeps a journal of what it did.
    final class ClaimSummaryManager {
        var store: any ClaimSummaryStore
        var validator: ClaimSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimSummaryEngine

        init(store: any ClaimSummaryStore, validator: ClaimSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimSummaryEngine) {
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
                throw Kit.Failure("claim summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimSummaryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimSummaryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim summary \(code) not found")
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

    static func newClaimSummaryManager(_ store: any ClaimSummaryStore, clock: any Kit.Clocks.Clock) -> ClaimSummaryManager {
        return ClaimSummaryManager(
            store: store,
            validator: defaultClaimSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimSummaryEngine()
        )
    }
}
