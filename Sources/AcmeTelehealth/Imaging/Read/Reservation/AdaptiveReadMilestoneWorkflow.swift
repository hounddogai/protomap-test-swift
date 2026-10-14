import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive read milestones through their life cycle and keeps a journal of what it did.
    final class AdaptiveReadMilestoneCoordinator {
        var store: any AdaptiveReadMilestoneStore
        var validator: AdaptiveReadMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveReadMilestoneEngine

        init(store: any AdaptiveReadMilestoneStore, validator: AdaptiveReadMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveReadMilestoneEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive read milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveReadMilestoneStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive read milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveReadMilestoneStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive read milestone \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newAdaptiveReadMilestoneCoordinator(_ store: any AdaptiveReadMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AdaptiveReadMilestoneCoordinator {
        return AdaptiveReadMilestoneCoordinator(
            store: store,
            validator: defaultAdaptiveReadMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveReadMilestoneEngine(flags)
        )
    }
}
