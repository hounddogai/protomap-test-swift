import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves regional inventory requests through their life cycle and keeps a journal of what it did.
    final class RegionalInventoryRequestWorkflow {
        var store: any RegionalInventoryRequestStore
        var validator: RegionalInventoryRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalInventoryRequestEngine

        init(store: any RegionalInventoryRequestStore, validator: RegionalInventoryRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalInventoryRequestEngine) {
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
                throw Kit.Failure("regional inventory request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalInventoryRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional inventory request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalInventoryRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional inventory request \(code) not found")
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

    static func newRegionalInventoryRequestWorkflow(_ store: any RegionalInventoryRequestStore, clock: any Kit.Clocks.Clock) -> RegionalInventoryRequestWorkflow {
        return RegionalInventoryRequestWorkflow(
            store: store,
            validator: defaultRegionalInventoryRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalInventoryRequestEngine()
        )
    }
}
