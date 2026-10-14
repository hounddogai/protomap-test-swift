import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial variances through their life cycle and keeps a journal of what it did.
    final class DenialVarianceDesk {
        var store: any DenialVarianceStore
        var validator: DenialVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialVarianceEngine

        init(store: any DenialVarianceStore, validator: DenialVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialVarianceEngine) {
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
                throw Kit.Failure("denial variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialVarianceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialVarianceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial variance \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newDenialVarianceDesk(_ store: any DenialVarianceStore, clock: any Kit.Clocks.Clock) -> DenialVarianceDesk {
        return DenialVarianceDesk(
            store: store,
            validator: defaultDenialVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialVarianceEngine()
        )
    }
}
