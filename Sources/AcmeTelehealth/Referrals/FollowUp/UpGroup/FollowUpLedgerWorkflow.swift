import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up ledgers through their life cycle and keeps a journal of what it did.
    final class FollowUpLedgerService {
        var store: any FollowUpLedgerStore
        var validator: FollowUpLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpLedgerEngine

        init(store: any FollowUpLedgerStore, validator: FollowUpLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpLedgerEngine) {
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
                throw Kit.Failure("follow up ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpLedgerStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpLedgerStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up ledger \(code) not found")
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

    static func newFollowUpLedgerService(_ store: any FollowUpLedgerStore, clock: any Kit.Clocks.Clock) -> FollowUpLedgerService {
        return FollowUpLedgerService(
            store: store,
            validator: defaultFollowUpLedgerValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpLedgerEngine()
        )
    }
}
