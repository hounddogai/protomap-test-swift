import AcmePlatform
import Foundation

extension Staffing {
    /// Moves lenient credential checkpoints through their life cycle and keeps a journal of what it did.
    final class LenientCredentialCheckpointDesk {
        var store: any LenientCredentialCheckpointStore
        var validator: LenientCredentialCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientCredentialCheckpointEngine

        init(store: any LenientCredentialCheckpointStore, validator: LenientCredentialCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientCredentialCheckpointEngine) {
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
                throw Kit.Failure("lenient credential checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientCredentialCheckpointStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient credential checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientCredentialCheckpointStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient credential checkpoint \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newLenientCredentialCheckpointDesk(_ store: any LenientCredentialCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientCredentialCheckpointDesk {
        return LenientCredentialCheckpointDesk(
            store: store,
            validator: defaultLenientCredentialCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientCredentialCheckpointEngine(flags)
        )
    }
}
