import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance batches through their life cycle and keeps a journal of what it did.
    final class RemittanceBatchWorkflow {
        var store: any RemittanceBatchStore
        var validator: RemittanceBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RemittanceBatchStore, validator: RemittanceBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("remittance batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceBatchStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceBatchStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newRemittanceBatchWorkflow(_ store: any RemittanceBatchStore, clock: any Kit.Clocks.Clock) -> RemittanceBatchWorkflow {
        return RemittanceBatchWorkflow(
            store: store,
            validator: defaultRemittanceBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
