import AcmePlatform
import Foundation

extension Staffing {
    /// Moves seasonal skill mix audits through their life cycle and keeps a journal of what it did.
    final class SeasonalSkillMixAuditCoordinator {
        var store: any SeasonalSkillMixAuditStore
        var validator: SeasonalSkillMixAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalSkillMixAuditStore, validator: SeasonalSkillMixAuditValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal skill mix audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalSkillMixAuditStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal skill mix audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalSkillMixAuditStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newSeasonalSkillMixAuditCoordinator(_ store: any SeasonalSkillMixAuditStore, clock: any Kit.Clocks.Clock) -> SeasonalSkillMixAuditCoordinator {
        return SeasonalSkillMixAuditCoordinator(
            store: store,
            validator: defaultSeasonalSkillMixAuditValidator(),
            clock: clock,
            journal: []
        )
    }
}
