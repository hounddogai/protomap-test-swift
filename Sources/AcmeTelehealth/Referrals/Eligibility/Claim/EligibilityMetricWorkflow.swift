import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility metrics through their life cycle and keeps a journal of what it did.
    final class EligibilityMetricCoordinator {
        var store: any EligibilityMetricStore
        var validator: EligibilityMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any EligibilityMetricStore, validator: EligibilityMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("eligibility metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityMetricStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityMetricStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newEligibilityMetricCoordinator(_ store: any EligibilityMetricStore, clock: any Kit.Clocks.Clock) -> EligibilityMetricCoordinator {
        return EligibilityMetricCoordinator(
            store: store,
            validator: defaultEligibilityMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
