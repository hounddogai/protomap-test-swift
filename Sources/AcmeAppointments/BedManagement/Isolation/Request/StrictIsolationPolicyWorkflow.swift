import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves strict isolation policies through their life cycle and keeps a journal of what it did.
    final class StrictIsolationPolicyManager {
        var store: any StrictIsolationPolicyStore
        var validator: StrictIsolationPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictIsolationPolicyStore, validator: StrictIsolationPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("strict isolation policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictIsolationPolicyStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict isolation policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictIsolationPolicyStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newStrictIsolationPolicyManager(_ store: any StrictIsolationPolicyStore, clock: any Kit.Clocks.Clock) -> StrictIsolationPolicyManager {
        return StrictIsolationPolicyManager(
            store: store,
            validator: defaultStrictIsolationPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
