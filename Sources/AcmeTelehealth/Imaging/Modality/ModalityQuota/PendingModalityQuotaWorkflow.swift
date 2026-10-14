import AcmePlatform
import Foundation

extension Imaging {
    /// Moves pending modality quotas through their life cycle and keeps a journal of what it did.
    final class PendingModalityQuotaDesk {
        var store: any PendingModalityQuotaStore
        var validator: PendingModalityQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingModalityQuotaEngine

        init(store: any PendingModalityQuotaStore, validator: PendingModalityQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingModalityQuotaEngine) {
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
                throw Kit.Failure("pending modality quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingModalityQuotaStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending modality quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingModalityQuotaStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending modality quota \(code) not found")
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

    static func newPendingModalityQuotaDesk(_ store: any PendingModalityQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingModalityQuotaDesk {
        return PendingModalityQuotaDesk(
            store: store,
            validator: defaultPendingModalityQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingModalityQuotaEngine(flags)
        )
    }
}
