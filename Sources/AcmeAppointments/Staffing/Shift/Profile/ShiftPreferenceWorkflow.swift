import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift preferences through their life cycle and keeps a journal of what it did.
    final class ShiftPreferenceDesk {
        var store: any ShiftPreferenceStore
        var validator: ShiftPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftPreferenceEngine

        init(store: any ShiftPreferenceStore, validator: ShiftPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftPreferenceEngine) {
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
                throw Kit.Failure("shift preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftPreferenceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftPreferenceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift preference \(code) not found")
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

    static func newShiftPreferenceDesk(_ store: any ShiftPreferenceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ShiftPreferenceDesk {
        return ShiftPreferenceDesk(
            store: store,
            validator: defaultShiftPreferenceValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftPreferenceEngine(flags)
        )
    }
}
