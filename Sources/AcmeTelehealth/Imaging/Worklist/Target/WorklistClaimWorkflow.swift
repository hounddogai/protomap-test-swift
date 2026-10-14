import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist claims through their life cycle and keeps a journal of what it did.
    final class WorklistClaimManager {
        var store: any WorklistClaimStore
        var validator: WorklistClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistClaimStore, validator: WorklistClaimValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("worklist claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistClaimStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistClaimStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newWorklistClaimManager(_ store: any WorklistClaimStore, clock: any Kit.Clocks.Clock) -> WorklistClaimManager {
        return WorklistClaimManager(
            store: store,
            validator: defaultWorklistClaimValidator(),
            clock: clock,
            journal: []
        )
    }
}
