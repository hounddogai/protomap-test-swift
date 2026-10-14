import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding agreements through their life cycle and keeps a journal of what it did.
    final class RoundingAgreementWorkflow {
        var store: any RoundingAgreementStore
        var validator: RoundingAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RoundingAgreementStore, validator: RoundingAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rounding agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRoundingAgreementWorkflow(_ store: any RoundingAgreementStore, clock: any Kit.Clocks.Clock) -> RoundingAgreementWorkflow {
        return RoundingAgreementWorkflow(
            store: store,
            validator: defaultRoundingAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
