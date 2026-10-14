import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier assignments through their life cycle and keeps a journal of what it did.
    final class CourierAssignmentDesk {
        var store: any CourierAssignmentStore
        var validator: CourierAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierAssignmentEngine

        init(store: any CourierAssignmentStore, validator: CourierAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierAssignmentEngine) {
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
                throw Kit.Failure("courier assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierAssignmentStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierAssignmentStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier assignment \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCourierAssignmentDesk(_ store: any CourierAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CourierAssignmentDesk {
        return CourierAssignmentDesk(
            store: store,
            validator: defaultCourierAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierAssignmentEngine(flags)
        )
    }
}
