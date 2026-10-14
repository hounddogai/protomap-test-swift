import AcmePlatform
import Foundation

extension Referrals {
    /// Moves seasonal follow up bundles through their life cycle and keeps a journal of what it did.
    final class SeasonalFollowUpBundleWorkflow {
        var store: any SeasonalFollowUpBundleStore
        var validator: SeasonalFollowUpBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalFollowUpBundleEngine

        init(store: any SeasonalFollowUpBundleStore, validator: SeasonalFollowUpBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalFollowUpBundleEngine) {
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
                throw Kit.Failure("seasonal follow up bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalFollowUpBundleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal follow up bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalFollowUpBundleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal follow up bundle \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newSeasonalFollowUpBundleWorkflow(_ store: any SeasonalFollowUpBundleStore, clock: any Kit.Clocks.Clock) -> SeasonalFollowUpBundleWorkflow {
        return SeasonalFollowUpBundleWorkflow(
            store: store,
            validator: defaultSeasonalFollowUpBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalFollowUpBundleEngine()
        )
    }
}
