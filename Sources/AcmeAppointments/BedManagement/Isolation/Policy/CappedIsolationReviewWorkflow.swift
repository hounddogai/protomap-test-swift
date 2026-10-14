import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped isolation reviews through their life cycle and keeps a journal of what it did.
    final class CappedIsolationReviewWorkflow {
        var store: any CappedIsolationReviewStore
        var validator: CappedIsolationReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedIsolationReviewEngine

        init(store: any CappedIsolationReviewStore, validator: CappedIsolationReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedIsolationReviewEngine) {
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
                throw Kit.Failure("capped isolation review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedIsolationReviewStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped isolation review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedIsolationReviewStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped isolation review \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCappedIsolationReviewWorkflow(_ store: any CappedIsolationReviewStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedIsolationReviewWorkflow {
        return CappedIsolationReviewWorkflow(
            store: store,
            validator: defaultCappedIsolationReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedIsolationReviewEngine(flags)
        )
    }
}
