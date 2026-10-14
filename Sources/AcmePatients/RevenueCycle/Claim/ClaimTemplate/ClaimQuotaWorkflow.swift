import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim quotas through their life cycle and keeps a journal of what it did.
    final class ClaimQuotaDesk {
        var store: any ClaimQuotaStore
        var validator: ClaimQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimQuotaEngine

        init(store: any ClaimQuotaStore, validator: ClaimQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimQuotaEngine) {
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
                throw Kit.Failure("claim quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimQuotaStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimQuotaStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim quota \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newClaimQuotaDesk(_ store: any ClaimQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClaimQuotaDesk {
        return ClaimQuotaDesk(
            store: store,
            validator: defaultClaimQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimQuotaEngine(flags)
        )
    }
}
