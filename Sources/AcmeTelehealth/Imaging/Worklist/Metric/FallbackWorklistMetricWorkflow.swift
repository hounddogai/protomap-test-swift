import AcmePlatform
import Foundation

extension Imaging {
    /// Moves fallback worklist metrics through their life cycle and keeps a journal of what it did.
    final class FallbackWorklistMetricWorkflow {
        var store: any FallbackWorklistMetricStore
        var validator: FallbackWorklistMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackWorklistMetricEngine

        init(store: any FallbackWorklistMetricStore, validator: FallbackWorklistMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackWorklistMetricEngine) {
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
                throw Kit.Failure("fallback worklist metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackWorklistMetricStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback worklist metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackWorklistMetricStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback worklist metric \(code) not found")
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

    static func newFallbackWorklistMetricWorkflow(_ store: any FallbackWorklistMetricStore, clock: any Kit.Clocks.Clock) -> FallbackWorklistMetricWorkflow {
        return FallbackWorklistMetricWorkflow(
            store: store,
            validator: defaultFallbackWorklistMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackWorklistMetricEngine()
        )
    }
}
