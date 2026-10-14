import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance windows through their life cycle and keeps a journal of what it did.
    final class RemittanceWindowDesk {
        var store: any RemittanceWindowStore
        var validator: RemittanceWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceWindowEngine

        init(store: any RemittanceWindowStore, validator: RemittanceWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceWindowEngine) {
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
                throw Kit.Failure("remittance window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceWindowStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceWindowStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance window \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newRemittanceWindowDesk(_ store: any RemittanceWindowStore, clock: any Kit.Clocks.Clock) -> RemittanceWindowDesk {
        return RemittanceWindowDesk(
            store: store,
            validator: defaultRemittanceWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceWindowEngine()
        )
    }
}
