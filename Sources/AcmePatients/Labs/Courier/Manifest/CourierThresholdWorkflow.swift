import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier thresholds through their life cycle and keeps a journal of what it did.
    final class CourierThresholdManager {
        var store: any CourierThresholdStore
        var validator: CourierThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierThresholdEngine

        init(store: any CourierThresholdStore, validator: CourierThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierThresholdEngine) {
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
                throw Kit.Failure("courier threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierThresholdStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierThresholdStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier threshold \(code) not found")
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

    static func newCourierThresholdManager(_ store: any CourierThresholdStore, clock: any Kit.Clocks.Clock) -> CourierThresholdManager {
        return CourierThresholdManager(
            store: store,
            validator: defaultCourierThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierThresholdEngine()
        )
    }
}
