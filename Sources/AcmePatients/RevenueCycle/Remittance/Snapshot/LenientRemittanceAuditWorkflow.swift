import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves lenient remittance audits through their life cycle and keeps a journal of what it did.
    final class LenientRemittanceAuditWorkflow {
        var store: any LenientRemittanceAuditStore
        var validator: LenientRemittanceAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientRemittanceAuditEngine

        init(store: any LenientRemittanceAuditStore, validator: LenientRemittanceAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientRemittanceAuditEngine) {
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
                throw Kit.Failure("lenient remittance audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRemittanceAuditStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRemittanceAuditStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient remittance audit \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newLenientRemittanceAuditWorkflow(_ store: any LenientRemittanceAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientRemittanceAuditWorkflow {
        return LenientRemittanceAuditWorkflow(
            store: store,
            validator: defaultLenientRemittanceAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientRemittanceAuditEngine(flags)
        )
    }
}
