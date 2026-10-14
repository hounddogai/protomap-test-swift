import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves strict recall entries through their life cycle and keeps a journal of what it did.
    final class StrictRecallEntryService {
        var store: any StrictRecallEntryStore
        var validator: StrictRecallEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictRecallEntryStore, validator: StrictRecallEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict recall entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictRecallEntryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict recall entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictRecallEntryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newStrictRecallEntryService(_ store: any StrictRecallEntryStore, clock: any Kit.Clocks.Clock) -> StrictRecallEntryService {
        return StrictRecallEntryService(
            store: store,
            validator: defaultStrictRecallEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
