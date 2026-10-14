import AcmePlatform
import Foundation

extension Referrals {
    /// Moves weighted network quotas through their life cycle and keeps a journal of what it did.
    final class WeightedNetworkQuotaWorkflow {
        var store: any WeightedNetworkQuotaStore
        var validator: WeightedNetworkQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedNetworkQuotaStore, validator: WeightedNetworkQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted network quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedNetworkQuotaStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted network quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedNetworkQuotaStatus.stopped)
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

    static func newWeightedNetworkQuotaWorkflow(_ store: any WeightedNetworkQuotaStore, clock: any Kit.Clocks.Clock) -> WeightedNetworkQuotaWorkflow {
        return WeightedNetworkQuotaWorkflow(
            store: store,
            validator: defaultWeightedNetworkQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
