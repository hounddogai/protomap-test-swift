import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning variances through their life cycle and keeps a journal of what it did.
    final class CleaningVarianceManager {
        var store: any CleaningVarianceStore
        var validator: CleaningVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CleaningVarianceStore, validator: CleaningVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("cleaning variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningVarianceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningVarianceStatus.cancelled)
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

    static func newCleaningVarianceManager(_ store: any CleaningVarianceStore, clock: any Kit.Clocks.Clock) -> CleaningVarianceManager {
        return CleaningVarianceManager(
            store: store,
            validator: defaultCleaningVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
