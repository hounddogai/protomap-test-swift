import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense exceptions through their life cycle and keeps a journal of what it did.
    final class DispenseExceptionManager {
        var store: any DispenseExceptionStore
        var validator: DispenseExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DispenseExceptionStore, validator: DispenseExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseExceptionStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseExceptionStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newDispenseExceptionManager(_ store: any DispenseExceptionStore, clock: any Kit.Clocks.Clock) -> DispenseExceptionManager {
        return DispenseExceptionManager(
            store: store,
            validator: defaultDispenseExceptionValidator(),
            clock: clock,
            journal: []
        )
    }
}
