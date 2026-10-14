import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves manual census allocations through their life cycle and keeps a journal of what it did.
    final class ManualCensusAllocationManager {
        var store: any ManualCensusAllocationStore
        var validator: ManualCensusAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ManualCensusAllocationStore, validator: ManualCensusAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("manual census allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualCensusAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual census allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualCensusAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newManualCensusAllocationManager(_ store: any ManualCensusAllocationStore, clock: any Kit.Clocks.Clock) -> ManualCensusAllocationManager {
        return ManualCensusAllocationManager(
            store: store,
            validator: defaultManualCensusAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
