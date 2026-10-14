import AcmePlatform
import Foundation

extension Referrals {
    /// Moves default slot requests through their life cycle and keeps a journal of what it did.
    final class DefaultSlotRequestManager {
        var store: any DefaultSlotRequestStore
        var validator: DefaultSlotRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultSlotRequestStore, validator: DefaultSlotRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default slot request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultSlotRequestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default slot request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultSlotRequestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newDefaultSlotRequestManager(_ store: any DefaultSlotRequestStore, clock: any Kit.Clocks.Clock) -> DefaultSlotRequestManager {
        return DefaultSlotRequestManager(
            store: store,
            validator: defaultDefaultSlotRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
