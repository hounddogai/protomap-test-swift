import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol overrides through their life cycle and keeps a journal of what it did.
    final class CareProtocolOverrideWorkflow {
        var store: any CareProtocolOverrideStore
        var validator: CareProtocolOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolOverrideEngine

        init(store: any CareProtocolOverrideStore, validator: CareProtocolOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolOverrideEngine) {
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
                throw Kit.Failure("care protocol override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolOverrideStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolOverrideStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol override \(code) not found")
            }
            let result = engine.run(item)
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

    static func newCareProtocolOverrideWorkflow(_ store: any CareProtocolOverrideStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareProtocolOverrideWorkflow {
        return CareProtocolOverrideWorkflow(
            store: store,
            validator: defaultCareProtocolOverrideValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolOverrideEngine(flags)
        )
    }
}
