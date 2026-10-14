import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves tiered remittance allocations through their life cycle and keeps a journal of what it did.
    final class TieredRemittanceAllocationManager {
        var store: any TieredRemittanceAllocationStore
        var validator: TieredRemittanceAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredRemittanceAllocationStore, validator: TieredRemittanceAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered remittance allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRemittanceAllocationStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered remittance allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRemittanceAllocationStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newTieredRemittanceAllocationManager(_ store: any TieredRemittanceAllocationStore, clock: any Kit.Clocks.Clock) -> TieredRemittanceAllocationManager {
        return TieredRemittanceAllocationManager(
            store: store,
            validator: defaultTieredRemittanceAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
