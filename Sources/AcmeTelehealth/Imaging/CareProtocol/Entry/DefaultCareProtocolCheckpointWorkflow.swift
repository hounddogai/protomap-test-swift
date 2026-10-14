import AcmePlatform
import Foundation

extension Imaging {
    /// Moves default care protocol checkpoints through their life cycle and keeps a journal of what it did.
    final class DefaultCareProtocolCheckpointWorkflow {
        var store: any DefaultCareProtocolCheckpointStore
        var validator: DefaultCareProtocolCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCareProtocolCheckpointEngine

        init(store: any DefaultCareProtocolCheckpointStore, validator: DefaultCareProtocolCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCareProtocolCheckpointEngine) {
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
                throw Kit.Failure("default care protocol checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCareProtocolCheckpointStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care protocol checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCareProtocolCheckpointStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default care protocol checkpoint \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newDefaultCareProtocolCheckpointWorkflow(_ store: any DefaultCareProtocolCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCareProtocolCheckpointWorkflow {
        return DefaultCareProtocolCheckpointWorkflow(
            store: store,
            validator: defaultDefaultCareProtocolCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCareProtocolCheckpointEngine(flags)
        )
    }
}
