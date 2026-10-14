import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves pending claim reviews through their life cycle and keeps a journal of what it did.
    final class PendingClaimReviewService {
        var store: any PendingClaimReviewStore
        var validator: PendingClaimReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingClaimReviewEngine

        init(store: any PendingClaimReviewStore, validator: PendingClaimReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingClaimReviewEngine) {
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
                throw Kit.Failure("pending claim review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingClaimReviewStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending claim review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingClaimReviewStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending claim review \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newPendingClaimReviewService(_ store: any PendingClaimReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingClaimReviewService {
        return PendingClaimReviewService(
            store: store,
            validator: defaultPendingClaimReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingClaimReviewEngine(flags)
        )
    }
}
