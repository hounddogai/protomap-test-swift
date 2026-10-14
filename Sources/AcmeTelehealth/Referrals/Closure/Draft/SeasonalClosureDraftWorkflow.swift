import AcmePlatform
import Foundation

extension Referrals {
    /// Moves seasonal closure drafts through their life cycle and keeps a journal of what it did.
    final class SeasonalClosureDraftCoordinator {
        var store: any SeasonalClosureDraftStore
        var validator: SeasonalClosureDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalClosureDraftEngine

        init(store: any SeasonalClosureDraftStore, validator: SeasonalClosureDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalClosureDraftEngine) {
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
                throw Kit.Failure("seasonal closure draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalClosureDraftStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal closure draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalClosureDraftStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal closure draft \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newSeasonalClosureDraftCoordinator(_ store: any SeasonalClosureDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalClosureDraftCoordinator {
        return SeasonalClosureDraftCoordinator(
            store: store,
            validator: defaultSeasonalClosureDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalClosureDraftEngine(flags)
        )
    }
}
