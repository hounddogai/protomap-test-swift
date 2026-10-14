import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance agreements through their life cycle and keeps a journal of what it did.
    final class RemittanceAgreementManager {
        var store: any RemittanceAgreementStore
        var validator: RemittanceAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceAgreementEngine

        init(store: any RemittanceAgreementStore, validator: RemittanceAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceAgreementEngine) {
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
                throw Kit.Failure("remittance agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceAgreementStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceAgreementStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance agreement \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newRemittanceAgreementManager(_ store: any RemittanceAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceAgreementManager {
        return RemittanceAgreementManager(
            store: store,
            validator: defaultRemittanceAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceAgreementEngine(flags)
        )
    }
}
