import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves fallback isolation metrics through their life cycle and keeps a journal of what it did.
    final class FallbackIsolationMetricCoordinator {
        var store: any FallbackIsolationMetricStore
        var validator: FallbackIsolationMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackIsolationMetricStore, validator: FallbackIsolationMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback isolation metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackIsolationMetricStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback isolation metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackIsolationMetricStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newFallbackIsolationMetricCoordinator(_ store: any FallbackIsolationMetricStore, clock: any Kit.Clocks.Clock) -> FallbackIsolationMetricCoordinator {
        return FallbackIsolationMetricCoordinator(
            store: store,
            validator: defaultFallbackIsolationMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
