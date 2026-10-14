import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted transfer requests through their life cycle and keeps a journal of what it did.
    final class WeightedTransferRequestDesk {
        var store: any WeightedTransferRequestStore
        var validator: WeightedTransferRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WeightedTransferRequestStore, validator: WeightedTransferRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("weighted transfer request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedTransferRequestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedTransferRequestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newWeightedTransferRequestDesk(_ store: any WeightedTransferRequestStore, clock: any Kit.Clocks.Clock) -> WeightedTransferRequestDesk {
        return WeightedTransferRequestDesk(
            store: store,
            validator: defaultWeightedTransferRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
