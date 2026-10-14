import AcmePlatform
import Foundation

extension Labs {
    /// Moves manual result baselines through their life cycle and keeps a journal of what it did.
    final class ManualResultBaselineWorkflow {
        var store: any ManualResultBaselineStore
        var validator: ManualResultBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualResultBaselineEngine

        init(store: any ManualResultBaselineStore, validator: ManualResultBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualResultBaselineEngine) {
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
                throw Kit.Failure("manual result baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualResultBaselineStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual result baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualResultBaselineStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual result baseline \(code) not found")
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

    static func newManualResultBaselineWorkflow(_ store: any ManualResultBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualResultBaselineWorkflow {
        return ManualResultBaselineWorkflow(
            store: store,
            validator: defaultManualResultBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualResultBaselineEngine(flags)
        )
    }
}
