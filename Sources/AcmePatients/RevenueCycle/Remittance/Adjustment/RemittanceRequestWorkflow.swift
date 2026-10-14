import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance requests through their life cycle and keeps a journal of what it did.
    final class RemittanceRequestManager {
        var store: any RemittanceRequestStore
        var validator: RemittanceRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RemittanceRequestStore, validator: RemittanceRequestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("remittance request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceRequestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceRequestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newRemittanceRequestManager(_ store: any RemittanceRequestStore, clock: any Kit.Clocks.Clock) -> RemittanceRequestManager {
        return RemittanceRequestManager(
            store: store,
            validator: defaultRemittanceRequestValidator(),
            clock: clock,
            journal: []
        )
    }
}
