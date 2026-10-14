import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol thresholds through their life cycle and keeps a journal of what it did.
    final class CareProtocolThresholdManager {
        var store: any CareProtocolThresholdStore
        var validator: CareProtocolThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolThresholdEngine

        init(store: any CareProtocolThresholdStore, validator: CareProtocolThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolThresholdEngine) {
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
                throw Kit.Failure("care protocol threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolThresholdStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolThresholdStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol threshold \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCareProtocolThresholdManager(_ store: any CareProtocolThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareProtocolThresholdManager {
        return CareProtocolThresholdManager(
            store: store,
            validator: defaultCareProtocolThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolThresholdEngine(flags)
        )
    }
}
