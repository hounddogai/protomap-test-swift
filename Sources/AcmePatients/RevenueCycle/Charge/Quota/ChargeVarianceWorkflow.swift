import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge variances through their life cycle and keeps a journal of what it did.
    final class ChargeVarianceCoordinator {
        var store: any ChargeVarianceStore
        var validator: ChargeVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeVarianceEngine

        init(store: any ChargeVarianceStore, validator: ChargeVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeVarianceEngine) {
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
                throw Kit.Failure("charge variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeVarianceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeVarianceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge variance \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newChargeVarianceCoordinator(_ store: any ChargeVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ChargeVarianceCoordinator {
        return ChargeVarianceCoordinator(
            store: store,
            validator: defaultChargeVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeVarianceEngine(flags)
        )
    }
}
