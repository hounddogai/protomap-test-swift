import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier metrics through their life cycle and keeps a journal of what it did.
    final class CourierMetricCoordinator {
        var store: any CourierMetricStore
        var validator: CourierMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierMetricEngine

        init(store: any CourierMetricStore, validator: CourierMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierMetricEngine) {
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
                throw Kit.Failure("courier metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierMetricStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierMetricStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier metric \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newCourierMetricCoordinator(_ store: any CourierMetricStore, clock: any Kit.Clocks.Clock) -> CourierMetricCoordinator {
        return CourierMetricCoordinator(
            store: store,
            validator: defaultCourierMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierMetricEngine()
        )
    }
}
