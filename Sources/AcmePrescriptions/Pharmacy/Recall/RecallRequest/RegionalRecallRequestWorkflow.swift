import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves regional recall requests through their life cycle and keeps a journal of what it did.
    final class RegionalRecallRequestCoordinator {
        var store: any RegionalRecallRequestStore
        var validator: RegionalRecallRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalRecallRequestEngine

        init(store: any RegionalRecallRequestStore, validator: RegionalRecallRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalRecallRequestEngine) {
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
                throw Kit.Failure("regional recall request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalRecallRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional recall request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalRecallRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional recall request \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRegionalRecallRequestCoordinator(_ store: any RegionalRecallRequestStore, clock: any Kit.Clocks.Clock) -> RegionalRecallRequestCoordinator {
        return RegionalRecallRequestCoordinator(
            store: store,
            validator: defaultRegionalRecallRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalRecallRequestEngine()
        )
    }
}
