import AcmePlatform
import Foundation

extension Labs {
    /// Moves panel variances through their life cycle and keeps a journal of what it did.
    final class PanelVarianceService {
        var store: any PanelVarianceStore
        var validator: PanelVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PanelVarianceEngine

        init(store: any PanelVarianceStore, validator: PanelVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PanelVarianceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PanelVarianceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PanelVarianceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("panel variance \(code) not found")
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

    static func newPanelVarianceService(_ store: any PanelVarianceStore, clock: any Kit.Clocks.Clock) -> PanelVarianceService {
        return PanelVarianceService(
            store: store,
            validator: defaultPanelVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultPanelVarianceEngine()
        )
    }
}
