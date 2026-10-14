import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional handoff quotas through their life cycle and keeps a journal of what it did.
    final class RegionalHandoffQuotaService {
        var store: any RegionalHandoffQuotaStore
        var validator: RegionalHandoffQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalHandoffQuotaEngine

        init(store: any RegionalHandoffQuotaStore, validator: RegionalHandoffQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalHandoffQuotaEngine) {
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
                throw Kit.Failure("regional handoff quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalHandoffQuotaStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalHandoffQuotaStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff quota \(code) not found")
            }
            let result = engine.price(item)
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

    static func newRegionalHandoffQuotaService(_ store: any RegionalHandoffQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalHandoffQuotaService {
        return RegionalHandoffQuotaService(
            store: store,
            validator: defaultRegionalHandoffQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalHandoffQuotaEngine(flags)
        )
    }
}
