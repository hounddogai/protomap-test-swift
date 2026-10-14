import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel estimates through their life cycle and keeps a journal of what it did.
    final class PanelEstimateCoordinator {
        var store: any PanelEstimateStore
        var validator: PanelEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelEstimateEngine

        init(store: any PanelEstimateStore, validator: PanelEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelEstimateEngine) {
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
                throw Kit.Failure("panel estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelEstimateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelEstimateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel estimate \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newPanelEstimateCoordinator(_ store: any PanelEstimateStore, clock: any Kit.Clocks.Clock) -> PanelEstimateCoordinator {
        return PanelEstimateCoordinator(
            store: store,
            validator: defaultPanelEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelEstimateEngine()
        )
    }
}
