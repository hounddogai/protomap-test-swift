import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient program variances through their life cycle and keeps a journal of what it did.
    final class LenientProgramVarianceManager {
        var store: any LenientProgramVarianceStore
        var validator: LenientProgramVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientProgramVarianceEngine

        init(store: any LenientProgramVarianceStore, validator: LenientProgramVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientProgramVarianceEngine) {
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
                throw Kit.Failure("lenient program variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientProgramVarianceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient program variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientProgramVarianceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient program variance \(code) not found")
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

    static func newLenientProgramVarianceManager(_ store: any LenientProgramVarianceStore, clock: any Kit.Clocks.Clock) -> LenientProgramVarianceManager {
        return LenientProgramVarianceManager(
            store: store,
            validator: defaultLenientProgramVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientProgramVarianceEngine()
        )
    }
}
