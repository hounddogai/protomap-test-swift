import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap targets through their life cycle and keeps a journal of what it did.
    final class CareGapTargetWorkflow {
        var store: any CareGapTargetStore
        var validator: CareGapTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CareGapTargetStore, validator: CareGapTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("care gap target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapTargetStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapTargetStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newCareGapTargetWorkflow(_ store: any CareGapTargetStore, clock: any Kit.Clocks.Clock) -> CareGapTargetWorkflow {
        return CareGapTargetWorkflow(
            store: store,
            validator: defaultCareGapTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
