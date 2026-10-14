import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves strict care protocol targets through their life cycle and keeps a journal of what it did.
    final class StrictCareProtocolTargetWorkflow {
        var store: any StrictCareProtocolTargetStore
        var validator: StrictCareProtocolTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictCareProtocolTargetEngine

        init(store: any StrictCareProtocolTargetStore, validator: StrictCareProtocolTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictCareProtocolTargetEngine) {
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
                throw Kit.Failure("strict care protocol target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictCareProtocolTargetStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict care protocol target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictCareProtocolTargetStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict care protocol target \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newStrictCareProtocolTargetWorkflow(_ store: any StrictCareProtocolTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictCareProtocolTargetWorkflow {
        return StrictCareProtocolTargetWorkflow(
            store: store,
            validator: defaultStrictCareProtocolTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictCareProtocolTargetEngine(flags)
        )
    }
}
