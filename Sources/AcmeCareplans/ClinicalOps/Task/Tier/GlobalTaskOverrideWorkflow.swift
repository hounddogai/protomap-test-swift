import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global task overrides through their life cycle and keeps a journal of what it did.
    final class GlobalTaskOverrideWorkflow {
        var store: any GlobalTaskOverrideStore
        var validator: GlobalTaskOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalTaskOverrideEngine

        init(store: any GlobalTaskOverrideStore, validator: GlobalTaskOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalTaskOverrideEngine) {
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
                throw Kit.Failure("global task override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalTaskOverrideStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global task override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalTaskOverrideStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global task override \(code) not found")
            }
            let result = engine.run(item)
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

    static func newGlobalTaskOverrideWorkflow(_ store: any GlobalTaskOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalTaskOverrideWorkflow {
        return GlobalTaskOverrideWorkflow(
            store: store,
            validator: defaultGlobalTaskOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalTaskOverrideEngine(flags)
        )
    }
}
