import AcmePlatform
import Foundation

extension Consent {
    /// Moves legacy consent form requests through their life cycle and keeps a journal of what it did.
    final class LegacyConsentFormRequestService {
        var store: any LegacyConsentFormRequestStore
        var validator: LegacyConsentFormRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyConsentFormRequestEngine

        init(store: any LegacyConsentFormRequestStore, validator: LegacyConsentFormRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyConsentFormRequestEngine) {
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
                throw Kit.Failure("legacy consent form request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyConsentFormRequestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy consent form request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyConsentFormRequestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy consent form request \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newLegacyConsentFormRequestService(_ store: any LegacyConsentFormRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyConsentFormRequestService {
        return LegacyConsentFormRequestService(
            store: store,
            validator: defaultLegacyConsentFormRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyConsentFormRequestEngine(flags)
        )
    }
}
