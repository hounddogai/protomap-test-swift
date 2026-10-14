import AcmePlatform
import Foundation

extension Consent {
    /// Moves seasonal revocation policies through their life cycle and keeps a journal of what it did.
    final class SeasonalRevocationPolicyCoordinator {
        var store: any SeasonalRevocationPolicyStore
        var validator: SeasonalRevocationPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalRevocationPolicyEngine

        init(store: any SeasonalRevocationPolicyStore, validator: SeasonalRevocationPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalRevocationPolicyEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal revocation policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalRevocationPolicyStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal revocation policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalRevocationPolicyStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal revocation policy \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newSeasonalRevocationPolicyCoordinator(_ store: any SeasonalRevocationPolicyStore, clock: any Kit.Clocks.Clock) -> SeasonalRevocationPolicyCoordinator {
        return SeasonalRevocationPolicyCoordinator(
            store: store,
            validator: defaultSeasonalRevocationPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalRevocationPolicyEngine()
        )
    }
}
