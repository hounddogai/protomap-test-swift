import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves lenient cleaning estimates through their life cycle and keeps a journal of what it did.
    final class LenientCleaningEstimateWorkflow {
        var store: any LenientCleaningEstimateStore
        var validator: LenientCleaningEstimateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientCleaningEstimateEngine

        init(store: any LenientCleaningEstimateStore, validator: LenientCleaningEstimateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientCleaningEstimateEngine) {
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
                throw Kit.Failure("lenient cleaning estimate \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientCleaningEstimateStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient cleaning estimate \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientCleaningEstimateStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient cleaning estimate \(code) not found")
            }
            let result = engine.price(item)
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

    static func newLenientCleaningEstimateWorkflow(_ store: any LenientCleaningEstimateStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientCleaningEstimateWorkflow {
        return LenientCleaningEstimateWorkflow(
            store: store,
            validator: defaultLenientCleaningEstimateValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientCleaningEstimateEngine(flags)
        )
    }
}
