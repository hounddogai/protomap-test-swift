import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves regional handoff profiles through their life cycle and keeps a journal of what it did.
    final class RegionalHandoffProfileWorkflow {
        var store: any RegionalHandoffProfileStore
        var validator: RegionalHandoffProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalHandoffProfileEngine

        init(store: any RegionalHandoffProfileStore, validator: RegionalHandoffProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalHandoffProfileEngine) {
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
                throw Kit.Failure("regional handoff profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalHandoffProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalHandoffProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional handoff profile \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRegionalHandoffProfileWorkflow(_ store: any RegionalHandoffProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalHandoffProfileWorkflow {
        return RegionalHandoffProfileWorkflow(
            store: store,
            validator: defaultRegionalHandoffProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalHandoffProfileEngine(flags)
        )
    }
}
