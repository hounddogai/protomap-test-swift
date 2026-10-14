import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped reference range estimates through their life cycle and keeps a journal of what it did.
    final class CappedReferenceRangeEstimateWorkflow {
        var store: any CappedReferenceRangeEstimateStore
        var validator: CappedReferenceRangeEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedReferenceRangeEstimateEngine

        init(store: any CappedReferenceRangeEstimateStore, validator: CappedReferenceRangeEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedReferenceRangeEstimateEngine) {
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
                throw Kit.Failure("capped reference range estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedReferenceRangeEstimateStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped reference range estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedReferenceRangeEstimateStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped reference range estimate \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newCappedReferenceRangeEstimateWorkflow(_ store: any CappedReferenceRangeEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CappedReferenceRangeEstimateWorkflow {
        return CappedReferenceRangeEstimateWorkflow(
            store: store,
            validator: defaultCappedReferenceRangeEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedReferenceRangeEstimateEngine(flags)
        )
    }
}
