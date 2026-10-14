import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal priority mappings through their life cycle and keeps a journal of what it did.
    final class SeasonalPriorityMappingManager {
        var store: any SeasonalPriorityMappingStore
        var validator: SeasonalPriorityMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalPriorityMappingStore, validator: SeasonalPriorityMappingValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal priority mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalPriorityMappingStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal priority mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalPriorityMappingStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newSeasonalPriorityMappingManager(_ store: any SeasonalPriorityMappingStore, clock: any Kit.Clocks.Clock) -> SeasonalPriorityMappingManager {
        return SeasonalPriorityMappingManager(
            store: store,
            validator: defaultSeasonalPriorityMappingValidator(),
            clock: clock,
            journal: []
        )
    }
}
