import AcmePlatform
import Foundation

extension Consent {
    /// Moves tiered consent form requests through their life cycle and keeps a journal of what it did.
    final class TieredConsentFormRequestService {
        var store: any TieredConsentFormRequestStore
        var validator: TieredConsentFormRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredConsentFormRequestEngine

        init(store: any TieredConsentFormRequestStore, validator: TieredConsentFormRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredConsentFormRequestEngine) {
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
                throw Kit.Failure("tiered consent form request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredConsentFormRequestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered consent form request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredConsentFormRequestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered consent form request \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newTieredConsentFormRequestService(_ store: any TieredConsentFormRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredConsentFormRequestService {
        return TieredConsentFormRequestService(
            store: store,
            validator: defaultTieredConsentFormRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredConsentFormRequestEngine(flags)
        )
    }
}
