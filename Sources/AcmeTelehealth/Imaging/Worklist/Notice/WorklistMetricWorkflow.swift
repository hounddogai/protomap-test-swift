import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist metrics through their life cycle and keeps a journal of what it did.
    final class WorklistMetricCoordinator {
        var store: any WorklistMetricStore
        var validator: WorklistMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistMetricEngine

        init(store: any WorklistMetricStore, validator: WorklistMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistMetricEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistMetricStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistMetricStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist metric \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newWorklistMetricCoordinator(_ store: any WorklistMetricStore, clock: any Kit.Clocks.Clock) -> WorklistMetricCoordinator {
        return WorklistMetricCoordinator(
            store: store,
            validator: defaultWorklistMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistMetricEngine()
        )
    }
}
