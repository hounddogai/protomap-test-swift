import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves weighted transfer agreements through their life cycle and keeps a journal of what it did.
    final class WeightedTransferAgreementManager {
        var store: any WeightedTransferAgreementStore
        var validator: WeightedTransferAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WeightedTransferAgreementEngine

        init(store: any WeightedTransferAgreementStore, validator: WeightedTransferAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WeightedTransferAgreementEngine) {
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
                throw Kit.Failure("weighted transfer agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WeightedTransferAgreementStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WeightedTransferAgreementStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("weighted transfer agreement \(code) not found")
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

    static func newWeightedTransferAgreementManager(_ store: any WeightedTransferAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> WeightedTransferAgreementManager {
        return WeightedTransferAgreementManager(
            store: store,
            validator: defaultWeightedTransferAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultWeightedTransferAgreementEngine(flags)
        )
    }
}
