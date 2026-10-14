import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial baselines through their life cycle and keeps a journal of what it did.
    final class DenialBaselineWorkflow {
        var store: any DenialBaselineStore
        var validator: DenialBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialBaselineEngine

        init(store: any DenialBaselineStore, validator: DenialBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialBaselineEngine) {
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
                throw Kit.Failure("denial baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial baseline \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newDenialBaselineWorkflow(_ store: any DenialBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DenialBaselineWorkflow {
        return DenialBaselineWorkflow(
            store: store,
            validator: defaultDenialBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialBaselineEngine(flags)
        )
    }
}
