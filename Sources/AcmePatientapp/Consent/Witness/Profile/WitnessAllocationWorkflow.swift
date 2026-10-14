import AcmePlatform
import Foundation

extension Consent {
    /// Moves witness allocations through their life cycle and keeps a journal of what it did.
    final class WitnessAllocationWorkflow {
        var store: any WitnessAllocationStore
        var validator: WitnessAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any WitnessAllocationStore, validator: WitnessAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("witness allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WitnessAllocationStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("witness allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WitnessAllocationStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newWitnessAllocationWorkflow(_ store: any WitnessAllocationStore, clock: any Kit.Clocks.Clock) -> WitnessAllocationWorkflow {
        return WitnessAllocationWorkflow(
            store: store,
            validator: defaultWitnessAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
