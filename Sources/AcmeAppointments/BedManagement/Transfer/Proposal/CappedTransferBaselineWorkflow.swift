import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped transfer baselines through their life cycle and keeps a journal of what it did.
    final class CappedTransferBaselineWorkflow {
        var store: any CappedTransferBaselineStore
        var validator: CappedTransferBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedTransferBaselineStore, validator: CappedTransferBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped transfer baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedTransferBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped transfer baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedTransferBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newCappedTransferBaselineWorkflow(_ store: any CappedTransferBaselineStore, clock: any Kit.Clocks.Clock) -> CappedTransferBaselineWorkflow {
        return CappedTransferBaselineWorkflow(
            store: store,
            validator: defaultCappedTransferBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
