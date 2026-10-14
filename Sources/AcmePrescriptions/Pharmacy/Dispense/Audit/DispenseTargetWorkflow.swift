import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense targets through their life cycle and keeps a journal of what it did.
    final class DispenseTargetService {
        var store: any DispenseTargetStore
        var validator: DispenseTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DispenseTargetStore, validator: DispenseTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseTargetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseTargetStatus.expired)
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

    static func newDispenseTargetService(_ store: any DispenseTargetStore, clock: any Kit.Clocks.Clock) -> DispenseTargetService {
        return DispenseTargetService(
            store: store,
            validator: defaultDispenseTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
