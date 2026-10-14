import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves capped denial targets through their life cycle and keeps a journal of what it did.
    final class CappedDenialTargetDesk {
        var store: any CappedDenialTargetStore
        var validator: CappedDenialTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedDenialTargetStore, validator: CappedDenialTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped denial target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedDenialTargetStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped denial target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedDenialTargetStatus.stopped)
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

    static func newCappedDenialTargetDesk(_ store: any CappedDenialTargetStore, clock: any Kit.Clocks.Clock) -> CappedDenialTargetDesk {
        return CappedDenialTargetDesk(
            store: store,
            validator: defaultCappedDenialTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
