import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert agreements through their life cycle and keeps a journal of what it did.
    final class AlertAgreementService {
        var store: any AlertAgreementStore
        var validator: AlertAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertAgreementEngine

        init(store: any AlertAgreementStore, validator: AlertAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertAgreementEngine) {
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
                throw Kit.Failure("alert agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertAgreementStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertAgreementStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert agreement \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newAlertAgreementService(_ store: any AlertAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AlertAgreementService {
        return AlertAgreementService(
            store: store,
            validator: defaultAlertAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertAgreementEngine(flags)
        )
    }
}
