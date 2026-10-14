import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves default transfer agreements through their life cycle and keeps a journal of what it did.
    final class DefaultTransferAgreementService {
        var store: any DefaultTransferAgreementStore
        var validator: DefaultTransferAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultTransferAgreementEngine

        init(store: any DefaultTransferAgreementStore, validator: DefaultTransferAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultTransferAgreementEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default transfer agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultTransferAgreementStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default transfer agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultTransferAgreementStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default transfer agreement \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newDefaultTransferAgreementService(_ store: any DefaultTransferAgreementStore, clock: any Kit.Clocks.Clock) -> DefaultTransferAgreementService {
        return DefaultTransferAgreementService(
            store: store,
            validator: defaultDefaultTransferAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultTransferAgreementEngine()
        )
    }
}
