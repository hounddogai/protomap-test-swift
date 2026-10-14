import AcmePlatform
import Foundation

extension Staffing {
    /// Moves tiered skill mix digests through their life cycle and keeps a journal of what it did.
    final class TieredSkillMixDigestDesk {
        var store: any TieredSkillMixDigestStore
        var validator: TieredSkillMixDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredSkillMixDigestEngine

        init(store: any TieredSkillMixDigestStore, validator: TieredSkillMixDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredSkillMixDigestEngine) {
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
                throw Kit.Failure("tiered skill mix digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredSkillMixDigestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered skill mix digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredSkillMixDigestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered skill mix digest \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newTieredSkillMixDigestDesk(_ store: any TieredSkillMixDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredSkillMixDigestDesk {
        return TieredSkillMixDigestDesk(
            store: store,
            validator: defaultTieredSkillMixDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredSkillMixDigestEngine(flags)
        )
    }
}
