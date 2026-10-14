import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert quotas through their life cycle and keeps a journal of what it did.
    final class AlertQuotaManager {
        var store: any AlertQuotaStore
        var validator: AlertQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertQuotaEngine

        init(store: any AlertQuotaStore, validator: AlertQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertQuotaEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertQuotaStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertQuotaStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert quota \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newAlertQuotaManager(_ store: any AlertQuotaStore, clock: any Kit.Clocks.Clock) -> AlertQuotaManager {
        return AlertQuotaManager(
            store: store,
            validator: defaultAlertQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertQuotaEngine()
        )
    }
}
