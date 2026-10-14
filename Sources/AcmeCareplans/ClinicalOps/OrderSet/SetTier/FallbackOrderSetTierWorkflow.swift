import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves fallback order set tiers through their life cycle and keeps a journal of what it did.
    final class FallbackOrderSetTierManager {
        var store: any FallbackOrderSetTierStore
        var validator: FallbackOrderSetTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackOrderSetTierStore, validator: FallbackOrderSetTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("fallback order set tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackOrderSetTierStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback order set tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackOrderSetTierStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newFallbackOrderSetTierManager(_ store: any FallbackOrderSetTierStore, clock: any Kit.Clocks.Clock) -> FallbackOrderSetTierManager {
        return FallbackOrderSetTierManager(
            store: store,
            validator: defaultFallbackOrderSetTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
