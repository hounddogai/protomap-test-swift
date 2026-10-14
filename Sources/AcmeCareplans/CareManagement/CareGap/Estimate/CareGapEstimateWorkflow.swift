import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap estimates through their life cycle and keeps a journal of what it did.
    final class CareGapEstimateWorkflow {
        var store: any CareGapEstimateStore
        var validator: CareGapEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapEstimateEngine

        init(store: any CareGapEstimateStore, validator: CareGapEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapEstimateEngine) {
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
                throw Kit.Failure("care gap estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapEstimateStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapEstimateStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap estimate \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCareGapEstimateWorkflow(_ store: any CareGapEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareGapEstimateWorkflow {
        return CareGapEstimateWorkflow(
            store: store,
            validator: defaultCareGapEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapEstimateEngine(flags)
        )
    }
}
