import AcmePlatform
import Foundation

extension Labs {
    /// Moves pending result baselines through their life cycle and keeps a journal of what it did.
    final class PendingResultBaselineManager {
        var store: any PendingResultBaselineStore
        var validator: PendingResultBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingResultBaselineStore, validator: PendingResultBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending result baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingResultBaselineStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending result baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingResultBaselineStatus.stopped)
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

    static func newPendingResultBaselineManager(_ store: any PendingResultBaselineStore, clock: any Kit.Clocks.Clock) -> PendingResultBaselineManager {
        return PendingResultBaselineManager(
            store: store,
            validator: defaultPendingResultBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
