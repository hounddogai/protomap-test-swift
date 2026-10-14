import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves tiered program quotas through their life cycle and keeps a journal of what it did.
    final class TieredProgramQuotaService {
        var store: any TieredProgramQuotaStore
        var validator: TieredProgramQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredProgramQuotaEngine

        init(store: any TieredProgramQuotaStore, validator: TieredProgramQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredProgramQuotaEngine) {
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
                throw Kit.Failure("tiered program quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredProgramQuotaStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered program quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredProgramQuotaStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered program quota \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newTieredProgramQuotaService(_ store: any TieredProgramQuotaStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredProgramQuotaService {
        return TieredProgramQuotaService(
            store: store,
            validator: defaultTieredProgramQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredProgramQuotaEngine(flags)
        )
    }
}
