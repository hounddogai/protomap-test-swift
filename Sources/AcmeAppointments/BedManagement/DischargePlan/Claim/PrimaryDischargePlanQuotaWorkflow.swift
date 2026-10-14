import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary discharge plan quotas through their life cycle and keeps a journal of what it did.
    final class PrimaryDischargePlanQuotaDesk {
        var store: any PrimaryDischargePlanQuotaStore
        var validator: PrimaryDischargePlanQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryDischargePlanQuotaEngine

        init(store: any PrimaryDischargePlanQuotaStore, validator: PrimaryDischargePlanQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryDischargePlanQuotaEngine) {
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
                throw Kit.Failure("primary discharge plan quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryDischargePlanQuotaStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryDischargePlanQuotaStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary discharge plan quota \(code) not found")
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

    static func newPrimaryDischargePlanQuotaDesk(_ store: any PrimaryDischargePlanQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryDischargePlanQuotaDesk {
        return PrimaryDischargePlanQuotaDesk(
            store: store,
            validator: defaultPrimaryDischargePlanQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryDischargePlanQuotaEngine(flags)
        )
    }
}
