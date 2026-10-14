import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves transfer plans through their life cycle and keeps a journal of what it did.
    final class TransferPlanService {
        var store: any TransferPlanStore
        var validator: TransferPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TransferPlanStore, validator: TransferPlanValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("transfer plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TransferPlanStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("transfer plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TransferPlanStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newTransferPlanService(_ store: any TransferPlanStore, clock: any Kit.Clocks.Clock) -> TransferPlanService {
        return TransferPlanService(
            store: store,
            validator: defaultTransferPlanValidator(),
            clock: clock,
            journal: []
        )
    }
}
