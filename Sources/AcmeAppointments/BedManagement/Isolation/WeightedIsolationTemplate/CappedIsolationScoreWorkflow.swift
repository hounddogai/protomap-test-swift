import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped isolation scores through their life cycle and keeps a journal of what it did.
    final class CappedIsolationScoreWorkflow {
        var store: any CappedIsolationScoreStore
        var validator: CappedIsolationScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedIsolationScoreStore, validator: CappedIsolationScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped isolation score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedIsolationScoreStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped isolation score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedIsolationScoreStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newCappedIsolationScoreWorkflow(_ store: any CappedIsolationScoreStore, clock: any Kit.Clocks.Clock) -> CappedIsolationScoreWorkflow {
        return CappedIsolationScoreWorkflow(
            store: store,
            validator: defaultCappedIsolationScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
