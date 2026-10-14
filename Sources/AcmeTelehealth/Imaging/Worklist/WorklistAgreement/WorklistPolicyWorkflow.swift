import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist policies through their life cycle and keeps a journal of what it did.
    final class WorklistPolicyManager {
        var store: any WorklistPolicyStore
        var validator: WorklistPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WorklistPolicyStore, validator: WorklistPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("worklist policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistPolicyStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistPolicyStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newWorklistPolicyManager(_ store: any WorklistPolicyStore, clock: any Kit.Clocks.Clock) -> WorklistPolicyManager {
        return WorklistPolicyManager(
            store: store,
            validator: defaultWorklistPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
