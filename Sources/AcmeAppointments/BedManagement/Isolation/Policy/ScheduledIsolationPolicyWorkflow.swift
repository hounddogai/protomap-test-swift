import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled isolation policies through their life cycle and keeps a journal of what it did.
    final class ScheduledIsolationPolicyService {
        var store: any ScheduledIsolationPolicyStore
        var validator: ScheduledIsolationPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledIsolationPolicyEngine

        init(store: any ScheduledIsolationPolicyStore, validator: ScheduledIsolationPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledIsolationPolicyEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled isolation policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledIsolationPolicyStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled isolation policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledIsolationPolicyStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled isolation policy \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newScheduledIsolationPolicyService(_ store: any ScheduledIsolationPolicyStore, clock: any Kit.Clocks.Clock) -> ScheduledIsolationPolicyService {
        return ScheduledIsolationPolicyService(
            store: store,
            validator: defaultScheduledIsolationPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledIsolationPolicyEngine()
        )
    }
}
