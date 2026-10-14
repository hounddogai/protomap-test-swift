import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves isolation exceptions through their life cycle and keeps a journal of what it did.
    final class IsolationExceptionDesk {
        var store: any IsolationExceptionStore
        var validator: IsolationExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any IsolationExceptionStore, validator: IsolationExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("isolation exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(IsolationExceptionStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("isolation exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(IsolationExceptionStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newIsolationExceptionDesk(_ store: any IsolationExceptionStore, clock: any Kit.Clocks.Clock) -> IsolationExceptionDesk {
        return IsolationExceptionDesk(
            store: store,
            validator: defaultIsolationExceptionValidator(),
            clock: clock,
            journal: []
        )
    }
}
