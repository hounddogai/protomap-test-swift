import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves capped care protocol quotas through their life cycle and keeps a journal of what it did.
    final class CappedCareProtocolQuotaManager {
        var store: any CappedCareProtocolQuotaStore
        var validator: CappedCareProtocolQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedCareProtocolQuotaEngine

        init(store: any CappedCareProtocolQuotaStore, validator: CappedCareProtocolQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedCareProtocolQuotaEngine) {
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
                throw Kit.Failure("capped care protocol quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCareProtocolQuotaStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care protocol quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCareProtocolQuotaStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped care protocol quota \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCappedCareProtocolQuotaManager(_ store: any CappedCareProtocolQuotaStore, clock: any Kit.Clocks.Clock) -> CappedCareProtocolQuotaManager {
        return CappedCareProtocolQuotaManager(
            store: store,
            validator: defaultCappedCareProtocolQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedCareProtocolQuotaEngine()
        )
    }
}
