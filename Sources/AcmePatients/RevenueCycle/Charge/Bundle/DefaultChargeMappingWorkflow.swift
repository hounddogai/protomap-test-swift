import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves default charge mappings through their life cycle and keeps a journal of what it did.
    final class DefaultChargeMappingWorkflow {
        var store: any DefaultChargeMappingStore
        var validator: DefaultChargeMappingValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultChargeMappingEngine

        init(store: any DefaultChargeMappingStore, validator: DefaultChargeMappingValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultChargeMappingEngine) {
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
                throw Kit.Failure("default charge mapping \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultChargeMappingStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default charge mapping \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultChargeMappingStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default charge mapping \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newDefaultChargeMappingWorkflow(_ store: any DefaultChargeMappingStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultChargeMappingWorkflow {
        return DefaultChargeMappingWorkflow(
            store: store,
            validator: defaultDefaultChargeMappingValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultChargeMappingEngine(flags)
        )
    }
}
