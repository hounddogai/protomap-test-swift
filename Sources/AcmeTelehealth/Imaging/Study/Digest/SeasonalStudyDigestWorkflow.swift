import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal study digests through their life cycle and keeps a journal of what it did.
    final class SeasonalStudyDigestCoordinator {
        var store: any SeasonalStudyDigestStore
        var validator: SeasonalStudyDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalStudyDigestEngine

        init(store: any SeasonalStudyDigestStore, validator: SeasonalStudyDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalStudyDigestEngine) {
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
                throw Kit.Failure("seasonal study digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalStudyDigestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal study digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalStudyDigestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal study digest \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newSeasonalStudyDigestCoordinator(_ store: any SeasonalStudyDigestStore, clock: any Kit.Clocks.Clock) -> SeasonalStudyDigestCoordinator {
        return SeasonalStudyDigestCoordinator(
            store: store,
            validator: defaultSeasonalStudyDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalStudyDigestEngine()
        )
    }
}
