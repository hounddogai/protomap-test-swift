import AcmePlatform
import Foundation

extension Labs {
    /// Moves primary result policies through their life cycle and keeps a journal of what it did.
    final class PrimaryResultPolicyDesk {
        var store: any PrimaryResultPolicyStore
        var validator: PrimaryResultPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryResultPolicyStore, validator: PrimaryResultPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary result policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryResultPolicyStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary result policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryResultPolicyStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newPrimaryResultPolicyDesk(_ store: any PrimaryResultPolicyStore, clock: any Kit.Clocks.Clock) -> PrimaryResultPolicyDesk {
        return PrimaryResultPolicyDesk(
            store: store,
            validator: defaultPrimaryResultPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
