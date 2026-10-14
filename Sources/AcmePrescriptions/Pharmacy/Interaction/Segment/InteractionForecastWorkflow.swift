import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction forecasts through their life cycle and keeps a journal of what it did.
    final class InteractionForecastWorkflow {
        var store: any InteractionForecastStore
        var validator: InteractionForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionForecastEngine

        init(store: any InteractionForecastStore, validator: InteractionForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionForecastEngine) {
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
                throw Kit.Failure("interaction forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionForecastStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionForecastStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction forecast \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newInteractionForecastWorkflow(_ store: any InteractionForecastStore, clock: any Kit.Clocks.Clock) -> InteractionForecastWorkflow {
        return InteractionForecastWorkflow(
            store: store,
            validator: defaultInteractionForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionForecastEngine()
        )
    }
}
