import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional modality batches through their life cycle and keeps a journal of what it did.
    final class RegionalModalityBatchManager {
        var store: any RegionalModalityBatchStore
        var validator: RegionalModalityBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalModalityBatchEngine

        init(store: any RegionalModalityBatchStore, validator: RegionalModalityBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalModalityBatchEngine) {
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
                throw Kit.Failure("regional modality batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalModalityBatchStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional modality batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalModalityBatchStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional modality batch \(code) not found")
            }
            let result = engine.run(item)
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

    static func newRegionalModalityBatchManager(_ store: any RegionalModalityBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalModalityBatchManager {
        return RegionalModalityBatchManager(
            store: store,
            validator: defaultRegionalModalityBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalModalityBatchEngine(flags)
        )
    }
}
