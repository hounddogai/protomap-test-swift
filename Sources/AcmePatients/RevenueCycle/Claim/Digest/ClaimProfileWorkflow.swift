import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim profiles through their life cycle and keeps a journal of what it did.
    final class ClaimProfileWorkflow {
        var store: any ClaimProfileStore
        var validator: ClaimProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimProfileEngine

        init(store: any ClaimProfileStore, validator: ClaimProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimProfileEngine) {
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
                throw Kit.Failure("claim profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimProfileStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimProfileStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim profile \(code) not found")
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

    static func newClaimProfileWorkflow(_ store: any ClaimProfileStore, clock: any Kit.Clocks.Clock) -> ClaimProfileWorkflow {
        return ClaimProfileWorkflow(
            store: store,
            validator: defaultClaimProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimProfileEngine()
        )
    }
}
