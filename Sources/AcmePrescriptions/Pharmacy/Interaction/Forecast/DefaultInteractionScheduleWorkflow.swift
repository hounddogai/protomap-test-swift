import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves default interaction schedules through their life cycle and keeps a journal of what it did.
    final class DefaultInteractionScheduleService {
        var store: any DefaultInteractionScheduleStore
        var validator: DefaultInteractionScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultInteractionScheduleEngine

        init(store: any DefaultInteractionScheduleStore, validator: DefaultInteractionScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultInteractionScheduleEngine) {
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
                throw Kit.Failure("default interaction schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultInteractionScheduleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default interaction schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultInteractionScheduleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default interaction schedule \(code) not found")
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

    static func newDefaultInteractionScheduleService(_ store: any DefaultInteractionScheduleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultInteractionScheduleService {
        return DefaultInteractionScheduleService(
            store: store,
            validator: defaultDefaultInteractionScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultInteractionScheduleEngine(flags)
        )
    }
}
