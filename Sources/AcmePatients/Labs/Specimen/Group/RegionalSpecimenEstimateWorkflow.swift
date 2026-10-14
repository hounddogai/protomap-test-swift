import AcmePlatform
import Foundation

extension Labs {
    /// Moves regional specimen estimates through their life cycle and keeps a journal of what it did.
    final class RegionalSpecimenEstimateDesk {
        var store: any RegionalSpecimenEstimateStore
        var validator: RegionalSpecimenEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalSpecimenEstimateEngine

        init(store: any RegionalSpecimenEstimateStore, validator: RegionalSpecimenEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalSpecimenEstimateEngine) {
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
                throw Kit.Failure("regional specimen estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalSpecimenEstimateStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional specimen estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalSpecimenEstimateStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional specimen estimate \(code) not found")
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

    static func newRegionalSpecimenEstimateDesk(_ store: any RegionalSpecimenEstimateStore, clock: any Kit.Clocks.Clock) -> RegionalSpecimenEstimateDesk {
        return RegionalSpecimenEstimateDesk(
            store: store,
            validator: defaultRegionalSpecimenEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalSpecimenEstimateEngine()
        )
    }
}
