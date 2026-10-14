import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge metrics through their life cycle and keeps a journal of what it did.
    final class ChargeMetricService {
        var store: any ChargeMetricStore
        var validator: ChargeMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ChargeMetricStore, validator: ChargeMetricValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("charge metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeMetricStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeMetricStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newChargeMetricService(_ store: any ChargeMetricStore, clock: any Kit.Clocks.Clock) -> ChargeMetricService {
        return ChargeMetricService(
            store: store,
            validator: defaultChargeMetricValidator(),
            clock: clock,
            journal: []
        )
    }
}
