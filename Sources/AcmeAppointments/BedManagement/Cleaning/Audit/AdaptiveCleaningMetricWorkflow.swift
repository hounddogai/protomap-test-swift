import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves adaptive cleaning metrics through their life cycle and keeps a journal of what it did.
    final class AdaptiveCleaningMetricCoordinator {
        var store: any AdaptiveCleaningMetricStore
        var validator: AdaptiveCleaningMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveCleaningMetricStore, validator: AdaptiveCleaningMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive cleaning metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveCleaningMetricStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive cleaning metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveCleaningMetricStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newAdaptiveCleaningMetricCoordinator(_ store: any AdaptiveCleaningMetricStore, clock: any Kit.Clocks.Clock) -> AdaptiveCleaningMetricCoordinator {
        return AdaptiveCleaningMetricCoordinator(
            store: store,
            validator: defaultAdaptiveCleaningMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
