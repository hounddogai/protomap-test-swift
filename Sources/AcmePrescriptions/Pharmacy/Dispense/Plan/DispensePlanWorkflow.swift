import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense plans through their life cycle and keeps a journal of what it did.
    final class DispensePlanManager {
        var store: any DispensePlanStore
        var validator: DispensePlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispensePlanEngine

        init(store: any DispensePlanStore, validator: DispensePlanValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispensePlanEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispensePlanStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispensePlanStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense plan \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDispensePlanManager(_ store: any DispensePlanStore, clock: any Kit.Clocks.Clock) -> DispensePlanManager {
        return DispensePlanManager(
            store: store,
            validator: defaultDispensePlanValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispensePlanEngine()
        )
    }
}
