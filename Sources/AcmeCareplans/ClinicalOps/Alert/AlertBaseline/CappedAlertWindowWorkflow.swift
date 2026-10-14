import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves capped alert windows through their life cycle and keeps a journal of what it did.
    final class CappedAlertWindowDesk {
        var store: any CappedAlertWindowStore
        var validator: CappedAlertWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedAlertWindowStore, validator: CappedAlertWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped alert window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedAlertWindowStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped alert window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedAlertWindowStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newCappedAlertWindowDesk(_ store: any CappedAlertWindowStore, clock: any Kit.Clocks.Clock) -> CappedAlertWindowDesk {
        return CappedAlertWindowDesk(
            store: store,
            validator: defaultCappedAlertWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
