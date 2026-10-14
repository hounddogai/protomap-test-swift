import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves charge schedules through their life cycle and keeps a journal of what it did.
    final class ChargeScheduleManager {
        var store: any ChargeScheduleStore
        var validator: ChargeScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ChargeScheduleEngine

        init(store: any ChargeScheduleStore, validator: ChargeScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ChargeScheduleEngine) {
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
                throw Kit.Failure("charge schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ChargeScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ChargeScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("charge schedule \(code) not found")
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

    static func newChargeScheduleManager(_ store: any ChargeScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ChargeScheduleManager {
        return ChargeScheduleManager(
            store: store,
            validator: defaultChargeScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultChargeScheduleEngine(flags)
        )
    }
}
