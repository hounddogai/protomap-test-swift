import AcmePlatform
import Foundation

extension Imaging {
    /// Moves legacy study estimates through their life cycle and keeps a journal of what it did.
    final class LegacyStudyEstimateDesk {
        var store: any LegacyStudyEstimateStore
        var validator: LegacyStudyEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyStudyEstimateStore, validator: LegacyStudyEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy study estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyStudyEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy study estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyStudyEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newLegacyStudyEstimateDesk(_ store: any LegacyStudyEstimateStore, clock: any Kit.Clocks.Clock) -> LegacyStudyEstimateDesk {
        return LegacyStudyEstimateDesk(
            store: store,
            validator: defaultLegacyStudyEstimateValidator(),
            clock: clock,
            journal: []
        )
    }
}
