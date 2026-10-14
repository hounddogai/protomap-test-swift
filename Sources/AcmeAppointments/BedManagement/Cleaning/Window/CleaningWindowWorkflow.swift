import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning windows through their life cycle and keeps a journal of what it did.
    final class CleaningWindowService {
        var store: any CleaningWindowStore
        var validator: CleaningWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CleaningWindowStore, validator: CleaningWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("cleaning window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningWindowStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningWindowStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCleaningWindowService(_ store: any CleaningWindowStore, clock: any Kit.Clocks.Clock) -> CleaningWindowService {
        return CleaningWindowService(
            store: store,
            validator: defaultCleaningWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
