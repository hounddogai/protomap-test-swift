import AcmePlatform
import Foundation

extension Consent {
    /// Moves pending language forecasts through their life cycle and keeps a journal of what it did.
    final class PendingLanguageForecastWorkflow {
        var store: any PendingLanguageForecastStore
        var validator: PendingLanguageForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingLanguageForecastEngine

        init(store: any PendingLanguageForecastStore, validator: PendingLanguageForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingLanguageForecastEngine) {
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
                throw Kit.Failure("pending language forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingLanguageForecastStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending language forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingLanguageForecastStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending language forecast \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newPendingLanguageForecastWorkflow(_ store: any PendingLanguageForecastStore, clock: any Kit.Clocks.Clock) -> PendingLanguageForecastWorkflow {
        return PendingLanguageForecastWorkflow(
            store: store,
            validator: defaultPendingLanguageForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingLanguageForecastEngine()
        )
    }
}
