import AcmePlatform
import Foundation

extension Referrals {
    /// Moves scheduled network drafts through their life cycle and keeps a journal of what it did.
    final class ScheduledNetworkDraftWorkflow {
        var store: any ScheduledNetworkDraftStore
        var validator: ScheduledNetworkDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledNetworkDraftEngine

        init(store: any ScheduledNetworkDraftStore, validator: ScheduledNetworkDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledNetworkDraftEngine) {
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
                throw Kit.Failure("scheduled network draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledNetworkDraftStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled network draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledNetworkDraftStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled network draft \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newScheduledNetworkDraftWorkflow(_ store: any ScheduledNetworkDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledNetworkDraftWorkflow {
        return ScheduledNetworkDraftWorkflow(
            store: store,
            validator: defaultScheduledNetworkDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledNetworkDraftEngine(flags)
        )
    }
}
