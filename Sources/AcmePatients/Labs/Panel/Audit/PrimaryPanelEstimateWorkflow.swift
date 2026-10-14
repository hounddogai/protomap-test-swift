import AcmePlatform
import Foundation

extension Labs {
    /// Moves primary panel estimates through their life cycle and keeps a journal of what it did.
    final class PrimaryPanelEstimateCoordinator {
        var store: any PrimaryPanelEstimateStore
        var validator: PrimaryPanelEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryPanelEstimateEngine

        init(store: any PrimaryPanelEstimateStore, validator: PrimaryPanelEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryPanelEstimateEngine) {
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
                throw Kit.Failure("primary panel estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryPanelEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary panel estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryPanelEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary panel estimate \(code) not found")
            }
            let result = engine.price(item)
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

    static func newPrimaryPanelEstimateCoordinator(_ store: any PrimaryPanelEstimateStore, clock: any Kit.Clocks.Clock) -> PrimaryPanelEstimateCoordinator {
        return PrimaryPanelEstimateCoordinator(
            store: store,
            validator: defaultPrimaryPanelEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryPanelEstimateEngine()
        )
    }
}
