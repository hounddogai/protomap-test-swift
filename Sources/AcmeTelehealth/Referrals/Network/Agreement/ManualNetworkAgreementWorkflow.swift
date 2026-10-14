import AcmePlatform
import Foundation

extension Referrals {
    /// Moves manual network agreements through their life cycle and keeps a journal of what it did.
    final class ManualNetworkAgreementService {
        var store: any ManualNetworkAgreementStore
        var validator: ManualNetworkAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualNetworkAgreementStore, validator: ManualNetworkAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual network agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualNetworkAgreementStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual network agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualNetworkAgreementStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newManualNetworkAgreementService(_ store: any ManualNetworkAgreementStore, clock: any Kit.Clocks.Clock) -> ManualNetworkAgreementService {
        return ManualNetworkAgreementService(
            store: store,
            validator: defaultManualNetworkAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
