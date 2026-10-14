import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure quotas through their life cycle and keeps a journal of what it did.
    final class ClosureQuotaWorkflow {
        var store: any ClosureQuotaStore
        var validator: ClosureQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureQuotaEngine

        init(store: any ClosureQuotaStore, validator: ClosureQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureQuotaEngine) {
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
                throw Kit.Failure("closure quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureQuotaStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureQuotaStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure quota \(code) not found")
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

    static func newClosureQuotaWorkflow(_ store: any ClosureQuotaStore, clock: any Kit.Clocks.Clock) -> ClosureQuotaWorkflow {
        return ClosureQuotaWorkflow(
            store: store,
            validator: defaultClosureQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureQuotaEngine()
        )
    }
}
