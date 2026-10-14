import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted authorization estimates through their life cycle and keeps a journal of what it did.
    final class WeightedAuthorizationEstimateService {
        var store: any WeightedAuthorizationEstimateStore
        var validator: WeightedAuthorizationEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedAuthorizationEstimateStore, validator: WeightedAuthorizationEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted authorization estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedAuthorizationEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted authorization estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedAuthorizationEstimateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newWeightedAuthorizationEstimateService(_ store: any WeightedAuthorizationEstimateStore, clock: any Kit.Clocks.Clock) -> WeightedAuthorizationEstimateService {
        return WeightedAuthorizationEstimateService(
            store: store,
            validator: defaultWeightedAuthorizationEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
