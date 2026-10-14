import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves manual outreach agreements through their life cycle and keeps a journal of what it did.
    final class ManualOutreachAgreementManager {
        var store: any ManualOutreachAgreementStore
        var validator: ManualOutreachAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualOutreachAgreementEngine

        init(store: any ManualOutreachAgreementStore, validator: ManualOutreachAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualOutreachAgreementEngine) {
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
                throw Kit.Failure("manual outreach agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualOutreachAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual outreach agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualOutreachAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual outreach agreement \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newManualOutreachAgreementManager(_ store: any ManualOutreachAgreementStore, clock: any Kit.Clocks.Clock) -> ManualOutreachAgreementManager {
        return ManualOutreachAgreementManager(
            store: store,
            validator: defaultManualOutreachAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualOutreachAgreementEngine()
        )
    }
}
