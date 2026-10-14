import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist cycles through their life cycle and keeps a journal of what it did.
    final class WorklistCycleDesk {
        var store: any WorklistCycleStore
        var validator: WorklistCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistCycleEngine

        init(store: any WorklistCycleStore, validator: WorklistCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistCycleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist cycle \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newWorklistCycleDesk(_ store: any WorklistCycleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WorklistCycleDesk {
        return WorklistCycleDesk(
            store: store,
            validator: defaultWorklistCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistCycleEngine(flags)
        )
    }
}
