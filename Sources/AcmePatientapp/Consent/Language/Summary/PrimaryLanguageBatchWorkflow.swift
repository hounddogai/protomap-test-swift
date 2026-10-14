import AcmePlatform
import Foundation

extension Consent {
    /// Moves primary language batches through their life cycle and keeps a journal of what it did.
    final class PrimaryLanguageBatchWorkflow {
        var store: any PrimaryLanguageBatchStore
        var validator: PrimaryLanguageBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryLanguageBatchStore, validator: PrimaryLanguageBatchValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary language batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryLanguageBatchStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary language batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryLanguageBatchStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newPrimaryLanguageBatchWorkflow(_ store: any PrimaryLanguageBatchStore, clock: any Kit.Clocks.Clock) -> PrimaryLanguageBatchWorkflow {
        return PrimaryLanguageBatchWorkflow(
            store: store,
            validator: defaultPrimaryLanguageBatchValidator(),
            clock: clock,
            journal: []
        )
    }
}
