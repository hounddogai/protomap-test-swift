import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge quotas through their life cycle and keeps a journal of what it did.
    final class ChargeQuotaService {
        var store: any ChargeQuotaStore
        var validator: ChargeQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeQuotaEngine

        init(store: any ChargeQuotaStore, validator: ChargeQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeQuotaEngine) {
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
                throw Kit.Failure("charge quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeQuotaStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeQuotaStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge quota \(code) not found")
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

    static func newChargeQuotaService(_ store: any ChargeQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ChargeQuotaService {
        return ChargeQuotaService(
            store: store,
            validator: defaultChargeQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeQuotaEngine(flags)
        )
    }
}
