import AcmePlatform
import Foundation

extension Referrals {
    /// Moves legacy network scores through their life cycle and keeps a journal of what it did.
    final class LegacyNetworkScoreWorkflow {
        var store: any LegacyNetworkScoreStore
        var validator: LegacyNetworkScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LegacyNetworkScoreStore, validator: LegacyNetworkScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("legacy network score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyNetworkScoreStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy network score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyNetworkScoreStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newLegacyNetworkScoreWorkflow(_ store: any LegacyNetworkScoreStore, clock: any Kit.Clocks.Clock) -> LegacyNetworkScoreWorkflow {
        return LegacyNetworkScoreWorkflow(
            store: store,
            validator: defaultLegacyNetworkScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
