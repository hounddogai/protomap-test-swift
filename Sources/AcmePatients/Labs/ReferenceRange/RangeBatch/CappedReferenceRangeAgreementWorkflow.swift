import AcmePlatform
import Foundation

extension Labs {
    /// Moves capped reference range agreements through their life cycle and keeps a journal of what it did.
    final class CappedReferenceRangeAgreementCoordinator {
        var store: any CappedReferenceRangeAgreementStore
        var validator: CappedReferenceRangeAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedReferenceRangeAgreementStore, validator: CappedReferenceRangeAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped reference range agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedReferenceRangeAgreementStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped reference range agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedReferenceRangeAgreementStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newCappedReferenceRangeAgreementCoordinator(_ store: any CappedReferenceRangeAgreementStore, clock: any Kit.Clocks.Clock) -> CappedReferenceRangeAgreementCoordinator {
        return CappedReferenceRangeAgreementCoordinator(
            store: store,
            validator: defaultCappedReferenceRangeAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
