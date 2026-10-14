import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves weighted claim templates through their life cycle and keeps a journal of what it did.
    final class WeightedClaimTemplateManager {
        var store: any WeightedClaimTemplateStore
        var validator: WeightedClaimTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedClaimTemplateStore, validator: WeightedClaimTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted claim template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedClaimTemplateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted claim template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedClaimTemplateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newWeightedClaimTemplateManager(_ store: any WeightedClaimTemplateStore, clock: any Kit.Clocks.Clock) -> WeightedClaimTemplateManager {
        return WeightedClaimTemplateManager(
            store: store,
            validator: defaultWeightedClaimTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
