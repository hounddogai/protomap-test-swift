import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation claims through their life cycle and keeps a journal of what it did.
    final class RevocationClaimManager {
        var store: any RevocationClaimStore
        var validator: RevocationClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationClaimEngine

        init(store: any RevocationClaimStore, validator: RevocationClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationClaimEngine) {
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
                throw Kit.Failure("revocation claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationClaimStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationClaimStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation claim \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newRevocationClaimManager(_ store: any RevocationClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RevocationClaimManager {
        return RevocationClaimManager(
            store: store,
            validator: defaultRevocationClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationClaimEngine(flags)
        )
    }
}
