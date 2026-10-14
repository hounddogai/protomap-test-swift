import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending consent form checkpoints through their life cycle and keeps a journal of what it did.
    final class PendingConsentFormCheckpointDesk {
        var store: any PendingConsentFormCheckpointStore
        var validator: PendingConsentFormCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingConsentFormCheckpointEngine

        init(store: any PendingConsentFormCheckpointStore, validator: PendingConsentFormCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingConsentFormCheckpointEngine) {
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
                throw Kit.Failure("pending consent form checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingConsentFormCheckpointStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending consent form checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingConsentFormCheckpointStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending consent form checkpoint \(code) not found")
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

    static func newPendingConsentFormCheckpointDesk(_ store: any PendingConsentFormCheckpointStore, clock: any Kit.Clocks.Clock) -> PendingConsentFormCheckpointDesk {
        return PendingConsentFormCheckpointDesk(
            store: store,
            validator: defaultPendingConsentFormCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingConsentFormCheckpointEngine()
        )
    }
}
