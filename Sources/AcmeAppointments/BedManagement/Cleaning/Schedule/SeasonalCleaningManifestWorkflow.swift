import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves seasonal cleaning manifests through their life cycle and keeps a journal of what it did.
    final class SeasonalCleaningManifestCoordinator {
        var store: any SeasonalCleaningManifestStore
        var validator: SeasonalCleaningManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalCleaningManifestEngine

        init(store: any SeasonalCleaningManifestStore, validator: SeasonalCleaningManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalCleaningManifestEngine) {
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
                throw Kit.Failure("seasonal cleaning manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCleaningManifestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal cleaning manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCleaningManifestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal cleaning manifest \(code) not found")
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

    static func newSeasonalCleaningManifestCoordinator(_ store: any SeasonalCleaningManifestStore, clock: any Kit.Clocks.Clock) -> SeasonalCleaningManifestCoordinator {
        return SeasonalCleaningManifestCoordinator(
            store: store,
            validator: defaultSeasonalCleaningManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalCleaningManifestEngine()
        )
    }
}
