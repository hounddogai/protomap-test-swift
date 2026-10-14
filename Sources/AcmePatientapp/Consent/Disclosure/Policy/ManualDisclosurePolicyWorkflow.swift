import AcmePlatform
import Foundation

extension Consent {
    /// Moves manual disclosure policies through their life cycle and keeps a journal of what it did.
    final class ManualDisclosurePolicyDesk {
        var store: any ManualDisclosurePolicyStore
        var validator: ManualDisclosurePolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualDisclosurePolicyStore, validator: ManualDisclosurePolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual disclosure policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualDisclosurePolicyStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual disclosure policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualDisclosurePolicyStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newManualDisclosurePolicyDesk(_ store: any ManualDisclosurePolicyStore, clock: any Kit.Clocks.Clock) -> ManualDisclosurePolicyDesk {
        return ManualDisclosurePolicyDesk(
            store: store,
            validator: defaultManualDisclosurePolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
