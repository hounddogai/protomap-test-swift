import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves fallback discharge plan metrics through their life cycle and keeps a journal of what it did.
    final class FallbackDischargePlanMetricCoordinator {
        var store: any FallbackDischargePlanMetricStore
        var validator: FallbackDischargePlanMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackDischargePlanMetricStore, validator: FallbackDischargePlanMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback discharge plan metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackDischargePlanMetricStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback discharge plan metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackDischargePlanMetricStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newFallbackDischargePlanMetricCoordinator(_ store: any FallbackDischargePlanMetricStore, clock: any Kit.Clocks.Clock) -> FallbackDischargePlanMetricCoordinator {
        return FallbackDischargePlanMetricCoordinator(
            store: store,
            validator: defaultFallbackDischargePlanMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
