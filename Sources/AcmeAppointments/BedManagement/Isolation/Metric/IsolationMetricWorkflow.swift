import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation metrics through their life cycle and keeps a journal of what it did.
    final class IsolationMetricWorkflow {
        var store: any IsolationMetricStore
        var validator: IsolationMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: IsolationMetricEngine

        init(store: any IsolationMetricStore, validator: IsolationMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: IsolationMetricEngine) {
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
                throw Kit.Failure("isolation metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationMetricStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationMetricStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation metric \(code) not found")
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

    static func newIsolationMetricWorkflow(_ store: any IsolationMetricStore, clock: any Kit.Clocks.Clock) -> IsolationMetricWorkflow {
        return IsolationMetricWorkflow(
            store: store,
            validator: defaultIsolationMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultIsolationMetricEngine()
        )
    }
}
