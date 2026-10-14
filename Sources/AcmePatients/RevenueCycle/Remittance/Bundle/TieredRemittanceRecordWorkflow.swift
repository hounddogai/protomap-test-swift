import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves tiered remittance records through their life cycle and keeps a journal of what it did.
    final class TieredRemittanceRecordDesk {
        var store: any TieredRemittanceRecordStore
        var validator: TieredRemittanceRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredRemittanceRecordStore, validator: TieredRemittanceRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered remittance record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredRemittanceRecordStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered remittance record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredRemittanceRecordStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newTieredRemittanceRecordDesk(_ store: any TieredRemittanceRecordStore, clock: any Kit.Clocks.Clock) -> TieredRemittanceRecordDesk {
        return TieredRemittanceRecordDesk(
            store: store,
            validator: defaultTieredRemittanceRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
