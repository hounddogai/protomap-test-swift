import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier profiles through their life cycle and keeps a journal of what it did.
    final class CourierProfileCoordinator {
        var store: any CourierProfileStore
        var validator: CourierProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CourierProfileEngine

        init(store: any CourierProfileStore, validator: CourierProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CourierProfileEngine) {
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
                throw Kit.Failure("courier profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierProfileStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierProfileStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier profile \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newCourierProfileCoordinator(_ store: any CourierProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CourierProfileCoordinator {
        return CourierProfileCoordinator(
            store: store,
            validator: defaultCourierProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultCourierProfileEngine(flags)
        )
    }
}
