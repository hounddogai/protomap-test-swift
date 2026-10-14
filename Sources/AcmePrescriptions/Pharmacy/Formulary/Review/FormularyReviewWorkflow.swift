import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary reviews through their life cycle and keeps a journal of what it did.
    final class FormularyReviewManager {
        var store: any FormularyReviewStore
        var validator: FormularyReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyReviewEngine

        init(store: any FormularyReviewStore, validator: FormularyReviewValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyReviewEngine) {
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
                throw Kit.Failure("formulary review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyReviewStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyReviewStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary review \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newFormularyReviewManager(_ store: any FormularyReviewStore, clock: any Kit.Clocks.Clock) -> FormularyReviewManager {
        return FormularyReviewManager(
            store: store,
            validator: defaultFormularyReviewValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyReviewEngine()
        )
    }
}
