import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier groups through their life cycle and keeps a journal of what it did.
    final class CourierGroupWorkflow {
        var store: any CourierGroupStore
        var validator: CourierGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierGroupEngine

        init(store: any CourierGroupStore, validator: CourierGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierGroupEngine) {
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
                throw Kit.Failure("courier group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierGroupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierGroupStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier group \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newCourierGroupWorkflow(_ store: any CourierGroupStore, clock: any Kit.Clocks.Clock) -> CourierGroupWorkflow {
        return CourierGroupWorkflow(
            store: store,
            validator: defaultCourierGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierGroupEngine()
        )
    }
}
