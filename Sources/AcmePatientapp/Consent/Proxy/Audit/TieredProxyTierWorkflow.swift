import AcmePlatform
import Foundation

extension Consent {
    /// Moves tiered proxy tiers through their life cycle and keeps a journal of what it did.
    final class TieredProxyTierDesk {
        var store: any TieredProxyTierStore
        var validator: TieredProxyTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredProxyTierEngine

        init(store: any TieredProxyTierStore, validator: TieredProxyTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredProxyTierEngine) {
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
                throw Kit.Failure("tiered proxy tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredProxyTierStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered proxy tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredProxyTierStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered proxy tier \(code) not found")
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

    static func newTieredProxyTierDesk(_ store: any TieredProxyTierStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredProxyTierDesk {
        return TieredProxyTierDesk(
            store: store,
            validator: defaultTieredProxyTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredProxyTierEngine(flags)
        )
    }
}
