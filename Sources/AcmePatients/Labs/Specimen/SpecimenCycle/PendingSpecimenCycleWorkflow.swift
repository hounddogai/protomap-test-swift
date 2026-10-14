import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending specimen cycles through their life cycle and keeps a journal of what it did.
    final class PendingSpecimenCycleWorkflow {
        var store: any PendingSpecimenCycleStore
        var validator: PendingSpecimenCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingSpecimenCycleEngine

        init(store: any PendingSpecimenCycleStore, validator: PendingSpecimenCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingSpecimenCycleEngine) {
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
                throw Kit.Failure("pending specimen cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingSpecimenCycleStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending specimen cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingSpecimenCycleStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending specimen cycle \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newPendingSpecimenCycleWorkflow(_ store: any PendingSpecimenCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PendingSpecimenCycleWorkflow {
        return PendingSpecimenCycleWorkflow(
            store: store,
            validator: defaultPendingSpecimenCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingSpecimenCycleEngine(flags)
        )
    }
}
