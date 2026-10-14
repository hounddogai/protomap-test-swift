import AcmePlatform
import Foundation

extension Consent {
    /// Moves adaptive revocation bundles through their life cycle and keeps a journal of what it did.
    final class AdaptiveRevocationBundleService {
        var store: any AdaptiveRevocationBundleStore
        var validator: AdaptiveRevocationBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveRevocationBundleEngine

        init(store: any AdaptiveRevocationBundleStore, validator: AdaptiveRevocationBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveRevocationBundleEngine) {
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
                throw Kit.Failure("adaptive revocation bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveRevocationBundleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive revocation bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveRevocationBundleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive revocation bundle \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAdaptiveRevocationBundleService(_ store: any AdaptiveRevocationBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveRevocationBundleService {
        return AdaptiveRevocationBundleService(
            store: store,
            validator: defaultAdaptiveRevocationBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveRevocationBundleEngine(flags)
        )
    }
}
