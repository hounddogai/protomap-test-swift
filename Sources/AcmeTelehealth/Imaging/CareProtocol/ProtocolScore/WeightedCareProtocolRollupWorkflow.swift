import AcmePlatform
import Foundation

extension Imaging {
    /// Moves weighted care protocol rollups through their life cycle and keeps a journal of what it did.
    final class WeightedCareProtocolRollupService {
        var store: any WeightedCareProtocolRollupStore
        var validator: WeightedCareProtocolRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedCareProtocolRollupStore, validator: WeightedCareProtocolRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted care protocol rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedCareProtocolRollupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted care protocol rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedCareProtocolRollupStatus.archived)
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

    static func newWeightedCareProtocolRollupService(_ store: any WeightedCareProtocolRollupStore, clock: any Kit.Clocks.Clock) -> WeightedCareProtocolRollupService {
        return WeightedCareProtocolRollupService(
            store: store,
            validator: defaultWeightedCareProtocolRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
