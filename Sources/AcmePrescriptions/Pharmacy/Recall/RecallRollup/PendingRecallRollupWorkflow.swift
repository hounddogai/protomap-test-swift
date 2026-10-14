import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves pending recall rollups through their life cycle and keeps a journal of what it did.
    final class PendingRecallRollupManager {
        var store: any PendingRecallRollupStore
        var validator: PendingRecallRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingRecallRollupStore, validator: PendingRecallRollupValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending recall rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingRecallRollupStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending recall rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingRecallRollupStatus.closed)
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

    static func newPendingRecallRollupManager(_ store: any PendingRecallRollupStore, clock: any Kit.Clocks.Clock) -> PendingRecallRollupManager {
        return PendingRecallRollupManager(
            store: store,
            validator: defaultPendingRecallRollupValidator(),
            clock: clock,
            journal: []
        )
    }
}
