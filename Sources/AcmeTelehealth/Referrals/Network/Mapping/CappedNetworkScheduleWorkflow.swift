import AcmePlatform
import Foundation

extension Referrals {
    /// Moves capped network schedules through their life cycle and keeps a journal of what it did.
    final class CappedNetworkScheduleWorkflow {
        var store: any CappedNetworkScheduleStore
        var validator: CappedNetworkScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedNetworkScheduleStore, validator: CappedNetworkScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped network schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedNetworkScheduleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped network schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedNetworkScheduleStatus.closed)
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

    static func newCappedNetworkScheduleWorkflow(_ store: any CappedNetworkScheduleStore, clock: any Kit.Clocks.Clock) -> CappedNetworkScheduleWorkflow {
        return CappedNetworkScheduleWorkflow(
            store: store,
            validator: defaultCappedNetworkScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
