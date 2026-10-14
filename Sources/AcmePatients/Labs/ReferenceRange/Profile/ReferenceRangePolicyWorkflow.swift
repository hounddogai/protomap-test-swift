import AcmePlatform
import Foundation

extension Labs {
    /// Moves reference range policies through their life cycle and keeps a journal of what it did.
    final class ReferenceRangePolicyDesk {
        var store: any ReferenceRangePolicyStore
        var validator: ReferenceRangePolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReferenceRangePolicyStore, validator: ReferenceRangePolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReferenceRangePolicyStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("reference range policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReferenceRangePolicyStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newReferenceRangePolicyDesk(_ store: any ReferenceRangePolicyStore, clock: any Kit.Clocks.Clock) -> ReferenceRangePolicyDesk {
        return ReferenceRangePolicyDesk(
            store: store,
            validator: defaultReferenceRangePolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
