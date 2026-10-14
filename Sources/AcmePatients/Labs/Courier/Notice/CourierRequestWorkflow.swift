import AcmePlatform
import Foundation

extension Labs {
    /// Moves courier requests through their life cycle and keeps a journal of what it did.
    final class CourierRequestManager {
        var store: any CourierRequestStore
        var validator: CourierRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CourierRequestStore, validator: CourierRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CourierRequestStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("courier request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CourierRequestStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newCourierRequestManager(_ store: any CourierRequestStore, clock: any Kit.Clocks.Clock) -> CourierRequestManager {
        return CourierRequestManager(
            store: store,
            validator: defaultCourierRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
