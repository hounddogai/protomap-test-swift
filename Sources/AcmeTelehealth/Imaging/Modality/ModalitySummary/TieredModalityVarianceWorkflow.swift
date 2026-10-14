import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered modality variances through their life cycle and keeps a journal of what it did.
    final class TieredModalityVarianceService {
        var store: any TieredModalityVarianceStore
        var validator: TieredModalityVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredModalityVarianceEngine

        init(store: any TieredModalityVarianceStore, validator: TieredModalityVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredModalityVarianceEngine) {
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
                throw Kit.Failure("tiered modality variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredModalityVarianceStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered modality variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredModalityVarianceStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered modality variance \(code) not found")
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

    static func newTieredModalityVarianceService(_ store: any TieredModalityVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredModalityVarianceService {
        return TieredModalityVarianceService(
            store: store,
            validator: defaultTieredModalityVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredModalityVarianceEngine(flags)
        )
    }
}
