import AcmePlatform
import Foundation

extension Labs {
    /// Moves accession variances through their life cycle and keeps a journal of what it did.
    final class AccessionVarianceDesk {
        var store: any AccessionVarianceStore
        var validator: AccessionVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AccessionVarianceEngine

        init(store: any AccessionVarianceStore, validator: AccessionVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AccessionVarianceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AccessionVarianceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AccessionVarianceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("accession variance \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newAccessionVarianceDesk(_ store: any AccessionVarianceStore, clock: any Kit.Clocks.Clock) -> AccessionVarianceDesk {
        return AccessionVarianceDesk(
            store: store,
            validator: defaultAccessionVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultAccessionVarianceEngine()
        )
    }
}
