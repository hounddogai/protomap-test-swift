import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending skill mix digests through their life cycle and keeps a journal of what it did.
    final class PendingSkillMixDigestManager {
        var store: any PendingSkillMixDigestStore
        var validator: PendingSkillMixDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingSkillMixDigestEngine

        init(store: any PendingSkillMixDigestStore, validator: PendingSkillMixDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingSkillMixDigestEngine) {
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
                throw Kit.Failure("pending skill mix digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingSkillMixDigestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending skill mix digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingSkillMixDigestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending skill mix digest \(code) not found")
            }
            let result = engine.price(item)
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

    static func newPendingSkillMixDigestManager(_ store: any PendingSkillMixDigestStore, clock: any Kit.Clocks.Clock) -> PendingSkillMixDigestManager {
        return PendingSkillMixDigestManager(
            store: store,
            validator: defaultPendingSkillMixDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingSkillMixDigestEngine()
        )
    }
}
