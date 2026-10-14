import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot schedules through their life cycle and keeps a journal of what it did.
    final class SlotScheduleService {
        var store: any SlotScheduleStore
        var validator: SlotScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SlotScheduleEngine

        init(store: any SlotScheduleStore, validator: SlotScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SlotScheduleEngine) {
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
                throw Kit.Failure("slot schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotScheduleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotScheduleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot schedule \(code) not found")
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

    static func newSlotScheduleService(_ store: any SlotScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SlotScheduleService {
        return SlotScheduleService(
            store: store,
            validator: defaultSlotScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultSlotScheduleEngine(flags)
        )
    }
}
