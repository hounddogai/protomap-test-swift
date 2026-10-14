import AcmePlatform
import Foundation

extension Consent {
    /// Moves global consent form batches through their life cycle and keeps a journal of what it did.
    final class GlobalConsentFormBatchService {
        var store: any GlobalConsentFormBatchStore
        var validator: GlobalConsentFormBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalConsentFormBatchEngine

        init(store: any GlobalConsentFormBatchStore, validator: GlobalConsentFormBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalConsentFormBatchEngine) {
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
                throw Kit.Failure("global consent form batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalConsentFormBatchStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global consent form batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalConsentFormBatchStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global consent form batch \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newGlobalConsentFormBatchService(_ store: any GlobalConsentFormBatchStore, clock: any Kit.Clocks.Clock) -> GlobalConsentFormBatchService {
        return GlobalConsentFormBatchService(
            store: store,
            validator: defaultGlobalConsentFormBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalConsentFormBatchEngine()
        )
    }
}
