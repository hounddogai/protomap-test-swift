import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves fallback census adjustments through their life cycle and keeps a journal of what it did.
    final class FallbackCensusAdjustmentService {
        var store: any FallbackCensusAdjustmentStore
        var validator: FallbackCensusAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackCensusAdjustmentEngine

        init(store: any FallbackCensusAdjustmentStore, validator: FallbackCensusAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackCensusAdjustmentEngine) {
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
                throw Kit.Failure("fallback census adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCensusAdjustmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback census adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCensusAdjustmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback census adjustment \(code) not found")
            }
            let result = engine.run(item)
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

    static func newFallbackCensusAdjustmentService(_ store: any FallbackCensusAdjustmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackCensusAdjustmentService {
        return FallbackCensusAdjustmentService(
            store: store,
            validator: defaultFallbackCensusAdjustmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackCensusAdjustmentEngine(flags)
        )
    }
}
