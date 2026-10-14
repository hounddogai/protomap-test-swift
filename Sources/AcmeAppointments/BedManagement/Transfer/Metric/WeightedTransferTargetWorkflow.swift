import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted transfer targets through their life cycle and keeps a journal of what it did.
    final class WeightedTransferTargetDesk {
        var store: any WeightedTransferTargetStore
        var validator: WeightedTransferTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedTransferTargetEngine

        init(store: any WeightedTransferTargetStore, validator: WeightedTransferTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedTransferTargetEngine) {
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
                throw Kit.Failure("weighted transfer target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedTransferTargetStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedTransferTargetStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer target \(code) not found")
            }
            let result = engine.price(item)
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

    static func newWeightedTransferTargetDesk(_ store: any WeightedTransferTargetStore, clock: any Kit.Clocks.Clock) -> WeightedTransferTargetDesk {
        return WeightedTransferTargetDesk(
            store: store,
            validator: defaultWeightedTransferTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedTransferTargetEngine()
        )
    }
}
