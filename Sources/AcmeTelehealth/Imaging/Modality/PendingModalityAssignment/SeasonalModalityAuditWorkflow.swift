import AcmePlatform
import Foundation

extension Imaging {
    /// Moves seasonal modality audits through their life cycle and keeps a journal of what it did.
    final class SeasonalModalityAuditManager {
        var store: any SeasonalModalityAuditStore
        var validator: SeasonalModalityAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalModalityAuditEngine

        init(store: any SeasonalModalityAuditStore, validator: SeasonalModalityAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalModalityAuditEngine) {
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
                throw Kit.Failure("seasonal modality audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalModalityAuditStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal modality audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalModalityAuditStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal modality audit \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newSeasonalModalityAuditManager(_ store: any SeasonalModalityAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalModalityAuditManager {
        return SeasonalModalityAuditManager(
            store: store,
            validator: defaultSeasonalModalityAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalModalityAuditEngine(flags)
        )
    }
}
