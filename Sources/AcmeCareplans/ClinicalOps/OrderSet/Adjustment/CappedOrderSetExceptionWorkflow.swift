import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves capped order set exceptions through their life cycle and keeps a journal of what it did.
    final class CappedOrderSetExceptionWorkflow {
        var store: any CappedOrderSetExceptionStore
        var validator: CappedOrderSetExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedOrderSetExceptionEngine

        init(store: any CappedOrderSetExceptionStore, validator: CappedOrderSetExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedOrderSetExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped order set exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedOrderSetExceptionStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped order set exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedOrderSetExceptionStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped order set exception \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCappedOrderSetExceptionWorkflow(_ store: any CappedOrderSetExceptionStore, clock: any Kit.Clocks.Clock) -> CappedOrderSetExceptionWorkflow {
        return CappedOrderSetExceptionWorkflow(
            store: store,
            validator: defaultCappedOrderSetExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedOrderSetExceptionEngine()
        )
    }
}
