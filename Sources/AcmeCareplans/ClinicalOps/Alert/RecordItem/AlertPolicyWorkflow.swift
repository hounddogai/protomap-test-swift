import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert policies through their life cycle and keeps a journal of what it did.
    final class AlertPolicyManager {
        var store: any AlertPolicyStore
        var validator: AlertPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertPolicyEngine

        init(store: any AlertPolicyStore, validator: AlertPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertPolicyEngine) {
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
                throw Kit.Failure("alert policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertPolicyStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertPolicyStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert policy \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAlertPolicyManager(_ store: any AlertPolicyStore, clock: any Kit.Clocks.Clock) -> AlertPolicyManager {
        return AlertPolicyManager(
            store: store,
            validator: defaultAlertPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertPolicyEngine()
        )
    }
}
