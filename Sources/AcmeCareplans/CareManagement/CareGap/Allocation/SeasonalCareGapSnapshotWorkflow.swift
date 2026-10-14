import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves seasonal care gap snapshots through their life cycle and keeps a journal of what it did.
    final class SeasonalCareGapSnapshotService {
        var store: any SeasonalCareGapSnapshotStore
        var validator: SeasonalCareGapSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalCareGapSnapshotEngine

        init(store: any SeasonalCareGapSnapshotStore, validator: SeasonalCareGapSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalCareGapSnapshotEngine) {
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
                throw Kit.Failure("seasonal care gap snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalCareGapSnapshotStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalCareGapSnapshotStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal care gap snapshot \(code) not found")
            }
            let result = engine.run(item)
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

    static func newSeasonalCareGapSnapshotService(_ store: any SeasonalCareGapSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalCareGapSnapshotService {
        return SeasonalCareGapSnapshotService(
            store: store,
            validator: defaultSeasonalCareGapSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalCareGapSnapshotEngine(flags)
        )
    }
}
