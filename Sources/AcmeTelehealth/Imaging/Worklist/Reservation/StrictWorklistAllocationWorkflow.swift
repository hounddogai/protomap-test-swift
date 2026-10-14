import AcmePlatform
import Foundation

extension Imaging {
    /// Moves strict worklist allocations through their life cycle and keeps a journal of what it did.
    final class StrictWorklistAllocationDesk {
        var store: any StrictWorklistAllocationStore
        var validator: StrictWorklistAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictWorklistAllocationEngine

        init(store: any StrictWorklistAllocationStore, validator: StrictWorklistAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictWorklistAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict worklist allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictWorklistAllocationStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict worklist allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictWorklistAllocationStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict worklist allocation \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newStrictWorklistAllocationDesk(_ store: any StrictWorklistAllocationStore, clock: any Kit.Clocks.Clock) -> StrictWorklistAllocationDesk {
        return StrictWorklistAllocationDesk(
            store: store,
            validator: defaultStrictWorklistAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictWorklistAllocationEngine()
        )
    }
}
