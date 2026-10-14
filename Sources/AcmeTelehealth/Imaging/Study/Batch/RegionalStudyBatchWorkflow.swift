import AcmePlatform
import Foundation

extension Imaging {
    /// Moves regional study batches through their life cycle and keeps a journal of what it did.
    final class RegionalStudyBatchCoordinator {
        var store: any RegionalStudyBatchStore
        var validator: RegionalStudyBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RegionalStudyBatchStore, validator: RegionalStudyBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("regional study batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalStudyBatchStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional study batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalStudyBatchStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newRegionalStudyBatchCoordinator(_ store: any RegionalStudyBatchStore, clock: any Kit.Clocks.Clock) -> RegionalStudyBatchCoordinator {
        return RegionalStudyBatchCoordinator(
            store: store,
            validator: defaultRegionalStudyBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
