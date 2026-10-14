import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped remittance audits through their life cycle and keeps a journal of what it did.
    final class CappedRemittanceAuditService {
        var store: any CappedRemittanceAuditStore
        var validator: CappedRemittanceAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedRemittanceAuditEngine

        init(store: any CappedRemittanceAuditStore, validator: CappedRemittanceAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedRemittanceAuditEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped remittance audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedRemittanceAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped remittance audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedRemittanceAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped remittance audit \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCappedRemittanceAuditService(_ store: any CappedRemittanceAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedRemittanceAuditService {
        return CappedRemittanceAuditService(
            store: store,
            validator: defaultCappedRemittanceAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedRemittanceAuditEngine(flags)
        )
    }
}
