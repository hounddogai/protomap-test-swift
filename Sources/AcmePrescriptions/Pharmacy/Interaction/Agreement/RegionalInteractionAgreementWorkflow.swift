import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves regional interaction agreements through their life cycle and keeps a journal of what it did.
    final class RegionalInteractionAgreementWorkflow {
        var store: any RegionalInteractionAgreementStore
        var validator: RegionalInteractionAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalInteractionAgreementStore, validator: RegionalInteractionAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional interaction agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalInteractionAgreementStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional interaction agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalInteractionAgreementStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newRegionalInteractionAgreementWorkflow(_ store: any RegionalInteractionAgreementStore, clock: any Kit.Clocks.Clock) -> RegionalInteractionAgreementWorkflow {
        return RegionalInteractionAgreementWorkflow(
            store: store,
            validator: defaultRegionalInteractionAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
