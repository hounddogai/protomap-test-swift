import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves pending care protocol milestones through their life cycle and keeps a journal of what it did.
    final class PendingCareProtocolMilestoneService {
        var store: any PendingCareProtocolMilestoneStore
        var validator: PendingCareProtocolMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingCareProtocolMilestoneEngine

        init(store: any PendingCareProtocolMilestoneStore, validator: PendingCareProtocolMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingCareProtocolMilestoneEngine) {
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
                throw Kit.Failure("pending care protocol milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCareProtocolMilestoneStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending care protocol milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCareProtocolMilestoneStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending care protocol milestone \(code) not found")
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

    static func newPendingCareProtocolMilestoneService(_ store: any PendingCareProtocolMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingCareProtocolMilestoneService {
        return PendingCareProtocolMilestoneService(
            store: store,
            validator: defaultPendingCareProtocolMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingCareProtocolMilestoneEngine(flags)
        )
    }
}
