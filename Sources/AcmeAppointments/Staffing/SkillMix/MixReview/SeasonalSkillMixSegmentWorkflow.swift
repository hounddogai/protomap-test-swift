import AcmePlatform
import Foundation

extension Staffing {
    /// Moves seasonal skill mix segments through their life cycle and keeps a journal of what it did.
    final class SeasonalSkillMixSegmentCoordinator {
        var store: any SeasonalSkillMixSegmentStore
        var validator: SeasonalSkillMixSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalSkillMixSegmentStore, validator: SeasonalSkillMixSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("seasonal skill mix segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalSkillMixSegmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal skill mix segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalSkillMixSegmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newSeasonalSkillMixSegmentCoordinator(_ store: any SeasonalSkillMixSegmentStore, clock: any Kit.Clocks.Clock) -> SeasonalSkillMixSegmentCoordinator {
        return SeasonalSkillMixSegmentCoordinator(
            store: store,
            validator: defaultSeasonalSkillMixSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
