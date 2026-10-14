import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness schedules through their life cycle and keeps a journal of what it did.
    final class WitnessScheduleManager {
        var store: any WitnessScheduleStore
        var validator: WitnessScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WitnessScheduleEngine

        init(store: any WitnessScheduleStore, validator: WitnessScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WitnessScheduleEngine) {
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
                throw Kit.Failure("witness schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness schedule \(code) not found")
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

    static func newWitnessScheduleManager(_ store: any WitnessScheduleStore, clock: any Kit.Clocks.Clock) -> WitnessScheduleManager {
        return WitnessScheduleManager(
            store: store,
            validator: defaultWitnessScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultWitnessScheduleEngine()
        )
    }
}
