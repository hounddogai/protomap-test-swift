import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves seasonal bed board preferences through their life cycle and keeps a journal of what it did.
    final class SeasonalBedBoardPreferenceCoordinator {
        var store: any SeasonalBedBoardPreferenceStore
        var validator: SeasonalBedBoardPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalBedBoardPreferenceStore, validator: SeasonalBedBoardPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal bed board preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalBedBoardPreferenceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal bed board preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalBedBoardPreferenceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newSeasonalBedBoardPreferenceCoordinator(_ store: any SeasonalBedBoardPreferenceStore, clock: any Kit.Clocks.Clock) -> SeasonalBedBoardPreferenceCoordinator {
        return SeasonalBedBoardPreferenceCoordinator(
            store: store,
            validator: defaultSeasonalBedBoardPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
