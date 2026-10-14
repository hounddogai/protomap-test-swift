import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding schedules through their life cycle and keeps a journal of what it did.
    final class RoundingScheduleService {
        var store: any RoundingScheduleStore
        var validator: RoundingScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RoundingScheduleEngine

        init(store: any RoundingScheduleStore, validator: RoundingScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RoundingScheduleEngine) {
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
                throw Kit.Failure("rounding schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingScheduleStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingScheduleStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding schedule \(code) not found")
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

    static func newRoundingScheduleService(_ store: any RoundingScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RoundingScheduleService {
        return RoundingScheduleService(
            store: store,
            validator: defaultRoundingScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRoundingScheduleEngine(flags)
        )
    }
}
