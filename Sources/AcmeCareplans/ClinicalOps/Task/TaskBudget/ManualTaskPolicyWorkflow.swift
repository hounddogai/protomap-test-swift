import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves manual task policies through their life cycle and keeps a journal of what it did.
    final class ManualTaskPolicyDesk {
        var store: any ManualTaskPolicyStore
        var validator: ManualTaskPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualTaskPolicyStore, validator: ManualTaskPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual task policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualTaskPolicyStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual task policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualTaskPolicyStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newManualTaskPolicyDesk(_ store: any ManualTaskPolicyStore, clock: any Kit.Clocks.Clock) -> ManualTaskPolicyDesk {
        return ManualTaskPolicyDesk(
            store: store,
            validator: defaultManualTaskPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
