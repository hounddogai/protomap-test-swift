import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves manual dispense mappings through their life cycle and keeps a journal of what it did.
    final class ManualDispenseMappingDesk {
        var store: any ManualDispenseMappingStore
        var validator: ManualDispenseMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualDispenseMappingEngine

        init(store: any ManualDispenseMappingStore, validator: ManualDispenseMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualDispenseMappingEngine) {
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
                throw Kit.Failure("manual dispense mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualDispenseMappingStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual dispense mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualDispenseMappingStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual dispense mapping \(code) not found")
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

    static func newManualDispenseMappingDesk(_ store: any ManualDispenseMappingStore, clock: any Kit.Clocks.Clock) -> ManualDispenseMappingDesk {
        return ManualDispenseMappingDesk(
            store: store,
            validator: defaultManualDispenseMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualDispenseMappingEngine()
        )
    }
}
