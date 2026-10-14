import AcmePlatform
import Foundation

extension Imaging {
    /// Moves modality forecasts through their life cycle and keeps a journal of what it did.
    final class ModalityForecastManager {
        var store: any ModalityForecastStore
        var validator: ModalityForecastValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ModalityForecastEngine

        init(store: any ModalityForecastStore, validator: ModalityForecastValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ModalityForecastEngine) {
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
                throw Kit.Failure("modality forecast \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ModalityForecastStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality forecast \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ModalityForecastStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("modality forecast \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newModalityForecastManager(_ store: any ModalityForecastStore, clock: any Kit.Clocks.Clock) -> ModalityForecastManager {
        return ModalityForecastManager(
            store: store,
            validator: defaultModalityForecastValidator(),
            clock: clock,
            journal: [],
            engine: defaultModalityForecastEngine()
        )
    }
}
