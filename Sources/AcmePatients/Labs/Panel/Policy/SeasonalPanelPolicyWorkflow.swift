import AcmePlatform
import Foundation

extension Labs {
    /// Moves seasonal panel policies through their life cycle and keeps a journal of what it did.
    final class SeasonalPanelPolicyCoordinator {
        var store: any SeasonalPanelPolicyStore
        var validator: SeasonalPanelPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SeasonalPanelPolicyStore, validator: SeasonalPanelPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("seasonal panel policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalPanelPolicyStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal panel policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalPanelPolicyStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newSeasonalPanelPolicyCoordinator(_ store: any SeasonalPanelPolicyStore, clock: any Kit.Clocks.Clock) -> SeasonalPanelPolicyCoordinator {
        return SeasonalPanelPolicyCoordinator(
            store: store,
            validator: defaultSeasonalPanelPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
