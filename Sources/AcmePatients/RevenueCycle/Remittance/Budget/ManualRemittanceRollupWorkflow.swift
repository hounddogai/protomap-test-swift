import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves manual remittance rollups through their life cycle and keeps a journal of what it did.
    final class ManualRemittanceRollupWorkflow {
        var store: any ManualRemittanceRollupStore
        var validator: ManualRemittanceRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualRemittanceRollupEngine

        init(store: any ManualRemittanceRollupStore, validator: ManualRemittanceRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualRemittanceRollupEngine) {
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
                throw Kit.Failure("manual remittance rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualRemittanceRollupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual remittance rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualRemittanceRollupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual remittance rollup \(code) not found")
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

    static func newManualRemittanceRollupWorkflow(_ store: any ManualRemittanceRollupStore, clock: any Kit.Clocks.Clock) -> ManualRemittanceRollupWorkflow {
        return ManualRemittanceRollupWorkflow(
            store: store,
            validator: defaultManualRemittanceRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualRemittanceRollupEngine()
        )
    }
}
