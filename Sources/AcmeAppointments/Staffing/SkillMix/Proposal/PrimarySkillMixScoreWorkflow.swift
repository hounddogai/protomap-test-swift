import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary skill mix scores through their life cycle and keeps a journal of what it did.
    final class PrimarySkillMixScoreService {
        var store: any PrimarySkillMixScoreStore
        var validator: PrimarySkillMixScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimarySkillMixScoreEngine

        init(store: any PrimarySkillMixScoreStore, validator: PrimarySkillMixScoreValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimarySkillMixScoreEngine) {
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
                throw Kit.Failure("primary skill mix score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimarySkillMixScoreStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary skill mix score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimarySkillMixScoreStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary skill mix score \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newPrimarySkillMixScoreService(_ store: any PrimarySkillMixScoreStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimarySkillMixScoreService {
        return PrimarySkillMixScoreService(
            store: store,
            validator: defaultPrimarySkillMixScoreValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimarySkillMixScoreEngine(flags)
        )
    }
}
