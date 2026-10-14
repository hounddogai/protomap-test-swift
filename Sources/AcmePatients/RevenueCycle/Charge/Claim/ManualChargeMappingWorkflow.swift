import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves manual charge mappings through their life cycle and keeps a journal of what it did.
    final class ManualChargeMappingCoordinator {
        var store: any ManualChargeMappingStore
        var validator: ManualChargeMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualChargeMappingEngine

        init(store: any ManualChargeMappingStore, validator: ManualChargeMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualChargeMappingEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual charge mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualChargeMappingStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual charge mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualChargeMappingStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual charge mapping \(code) not found")
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

    static func newManualChargeMappingCoordinator(_ store: any ManualChargeMappingStore, clock: any Kit.Clocks.Clock) -> ManualChargeMappingCoordinator {
        return ManualChargeMappingCoordinator(
            store: store,
            validator: defaultManualChargeMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualChargeMappingEngine()
        )
    }
}
