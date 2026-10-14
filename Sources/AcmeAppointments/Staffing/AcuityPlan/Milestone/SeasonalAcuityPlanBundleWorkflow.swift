import AcmePlatform
import Foundation

extension Staffing {
    /// Moves seasonal acuity plan bundles through their life cycle and keeps a journal of what it did.
    final class SeasonalAcuityPlanBundleDesk {
        var store: any SeasonalAcuityPlanBundleStore
        var validator: SeasonalAcuityPlanBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalAcuityPlanBundleStore, validator: SeasonalAcuityPlanBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("seasonal acuity plan bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalAcuityPlanBundleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal acuity plan bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalAcuityPlanBundleStatus.stopped)
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

    static func newSeasonalAcuityPlanBundleDesk(_ store: any SeasonalAcuityPlanBundleStore, clock: any Kit.Clocks.Clock) -> SeasonalAcuityPlanBundleDesk {
        return SeasonalAcuityPlanBundleDesk(
            store: store,
            validator: defaultSeasonalAcuityPlanBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
