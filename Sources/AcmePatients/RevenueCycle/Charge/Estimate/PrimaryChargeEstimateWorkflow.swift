import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves primary charge estimates through their life cycle and keeps a journal of what it did.
    final class PrimaryChargeEstimateCoordinator {
        var store: any PrimaryChargeEstimateStore
        var validator: PrimaryChargeEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryChargeEstimateEngine

        init(store: any PrimaryChargeEstimateStore, validator: PrimaryChargeEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryChargeEstimateEngine) {
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
                throw Kit.Failure("primary charge estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryChargeEstimateStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary charge estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryChargeEstimateStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary charge estimate \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newPrimaryChargeEstimateCoordinator(_ store: any PrimaryChargeEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryChargeEstimateCoordinator {
        return PrimaryChargeEstimateCoordinator(
            store: store,
            validator: defaultPrimaryChargeEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryChargeEstimateEngine(flags)
        )
    }
}
