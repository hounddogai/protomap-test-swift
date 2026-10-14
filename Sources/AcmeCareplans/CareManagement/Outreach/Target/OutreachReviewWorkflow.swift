import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach reviews through their life cycle and keeps a journal of what it did.
    final class OutreachReviewCoordinator {
        var store: any OutreachReviewStore
        var validator: OutreachReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OutreachReviewEngine

        init(store: any OutreachReviewStore, validator: OutreachReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OutreachReviewEngine) {
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
                throw Kit.Failure("outreach review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachReviewStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachReviewStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach review \(code) not found")
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

    static func newOutreachReviewCoordinator(_ store: any OutreachReviewStore, clock: any Kit.Clocks.Clock) -> OutreachReviewCoordinator {
        return OutreachReviewCoordinator(
            store: store,
            validator: defaultOutreachReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultOutreachReviewEngine()
        )
    }
}
