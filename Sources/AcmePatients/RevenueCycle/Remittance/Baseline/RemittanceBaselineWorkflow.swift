import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance baselines through their life cycle and keeps a journal of what it did.
    final class RemittanceBaselineWorkflow {
        var store: any RemittanceBaselineStore
        var validator: RemittanceBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceBaselineEngine

        init(store: any RemittanceBaselineStore, validator: RemittanceBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceBaselineEngine) {
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
                throw Kit.Failure("remittance baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceBaselineStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceBaselineStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance baseline \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRemittanceBaselineWorkflow(_ store: any RemittanceBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceBaselineWorkflow {
        return RemittanceBaselineWorkflow(
            store: store,
            validator: defaultRemittanceBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceBaselineEngine(flags)
        )
    }
}
