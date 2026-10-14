import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation batches through their life cycle and keeps a journal of what it did.
    final class RevocationBatchManager {
        var store: any RevocationBatchStore
        var validator: RevocationBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationBatchEngine

        init(store: any RevocationBatchStore, validator: RevocationBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationBatchEngine) {
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
                throw Kit.Failure("revocation batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationBatchStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationBatchStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation batch \(code) not found")
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

    static func newRevocationBatchManager(_ store: any RevocationBatchStore, clock: any Kit.Clocks.Clock) -> RevocationBatchManager {
        return RevocationBatchManager(
            store: store,
            validator: defaultRevocationBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationBatchEngine()
        )
    }
}
