import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves adaptive isolation reviews through their life cycle and keeps a journal of what it did.
    final class AdaptiveIsolationReviewWorkflow {
        var store: any AdaptiveIsolationReviewStore
        var validator: AdaptiveIsolationReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveIsolationReviewStore, validator: AdaptiveIsolationReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive isolation review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveIsolationReviewStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive isolation review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveIsolationReviewStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newAdaptiveIsolationReviewWorkflow(_ store: any AdaptiveIsolationReviewStore, clock: any Kit.Clocks.Clock) -> AdaptiveIsolationReviewWorkflow {
        return AdaptiveIsolationReviewWorkflow(
            store: store,
            validator: defaultAdaptiveIsolationReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
