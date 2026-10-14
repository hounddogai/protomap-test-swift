import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall forecasts through their life cycle and keeps a journal of what it did.
    final class RecallForecastCoordinator {
        var store: any RecallForecastStore
        var validator: RecallForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallForecastEngine

        init(store: any RecallForecastStore, validator: RecallForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallForecastEngine) {
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
                throw Kit.Failure("recall forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallForecastStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallForecastStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall forecast \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newRecallForecastCoordinator(_ store: any RecallForecastStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RecallForecastCoordinator {
        return RecallForecastCoordinator(
            store: store,
            validator: defaultRecallForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallForecastEngine(flags)
        )
    }
}
