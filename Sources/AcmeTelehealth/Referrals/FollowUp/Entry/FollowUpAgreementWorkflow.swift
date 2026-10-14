import AcmePlatform
import Foundation

extension Referrals {
    /// Moves follow up agreements through their life cycle and keeps a journal of what it did.
    final class FollowUpAgreementService {
        var store: any FollowUpAgreementStore
        var validator: FollowUpAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FollowUpAgreementEngine

        init(store: any FollowUpAgreementStore, validator: FollowUpAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FollowUpAgreementEngine) {
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
                throw Kit.Failure("follow up agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FollowUpAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FollowUpAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("follow up agreement \(code) not found")
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

    static func newFollowUpAgreementService(_ store: any FollowUpAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FollowUpAgreementService {
        return FollowUpAgreementService(
            store: store,
            validator: defaultFollowUpAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultFollowUpAgreementEngine(flags)
        )
    }
}
