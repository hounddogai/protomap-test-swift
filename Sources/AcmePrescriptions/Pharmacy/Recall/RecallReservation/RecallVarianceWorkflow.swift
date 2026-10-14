import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall variances through their life cycle and keeps a journal of what it did.
    final class RecallVarianceDesk {
        var store: any RecallVarianceStore
        var validator: RecallVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RecallVarianceStore, validator: RecallVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("recall variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallVarianceStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallVarianceStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newRecallVarianceDesk(_ store: any RecallVarianceStore, clock: any Kit.Clocks.Clock) -> RecallVarianceDesk {
        return RecallVarianceDesk(
            store: store,
            validator: defaultRecallVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
