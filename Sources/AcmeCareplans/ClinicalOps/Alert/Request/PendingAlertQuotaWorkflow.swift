import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves pending alert quotas through their life cycle and keeps a journal of what it did.
    final class PendingAlertQuotaService {
        var store: any PendingAlertQuotaStore
        var validator: PendingAlertQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingAlertQuotaEngine

        init(store: any PendingAlertQuotaStore, validator: PendingAlertQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingAlertQuotaEngine) {
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
                throw Kit.Failure("pending alert quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingAlertQuotaStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending alert quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingAlertQuotaStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending alert quota \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPendingAlertQuotaService(_ store: any PendingAlertQuotaStore, clock: any Kit.Clocks.Clock) -> PendingAlertQuotaService {
        return PendingAlertQuotaService(
            store: store,
            validator: defaultPendingAlertQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingAlertQuotaEngine()
        )
    }
}
