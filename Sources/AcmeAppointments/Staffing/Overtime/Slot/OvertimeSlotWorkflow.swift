import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime slots through their life cycle and keeps a journal of what it did.
    final class OvertimeSlotService {
        var store: any OvertimeSlotStore
        var validator: OvertimeSlotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeSlotEngine

        init(store: any OvertimeSlotStore, validator: OvertimeSlotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeSlotEngine) {
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
                throw Kit.Failure("overtime slot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeSlotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime slot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeSlotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime slot \(code) not found")
            }
            let result = engine.price(item)
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

    static func newOvertimeSlotService(_ store: any OvertimeSlotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OvertimeSlotService {
        return OvertimeSlotService(
            store: store,
            validator: defaultOvertimeSlotValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeSlotEngine(flags)
        )
    }
}
