import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending accession profiles through their life cycle and keeps a journal of what it did.
    final class PendingAccessionProfileWorkflow {
        var store: any PendingAccessionProfileStore
        var validator: PendingAccessionProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingAccessionProfileEngine

        init(store: any PendingAccessionProfileStore, validator: PendingAccessionProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingAccessionProfileEngine) {
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
                throw Kit.Failure("pending accession profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingAccessionProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending accession profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingAccessionProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending accession profile \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newPendingAccessionProfileWorkflow(_ store: any PendingAccessionProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingAccessionProfileWorkflow {
        return PendingAccessionProfileWorkflow(
            store: store,
            validator: defaultPendingAccessionProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingAccessionProfileEngine(flags)
        )
    }
}
