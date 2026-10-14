import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial allocations through their life cycle and keeps a journal of what it did.
    final class DenialAllocationDesk {
        var store: any DenialAllocationStore
        var validator: DenialAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialAllocationEngine

        init(store: any DenialAllocationStore, validator: DenialAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialAllocationEngine) {
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
                throw Kit.Failure("denial allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial allocation \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newDenialAllocationDesk(_ store: any DenialAllocationStore, clock: any Kit.Clocks.Clock) -> DenialAllocationDesk {
        return DenialAllocationDesk(
            store: store,
            validator: defaultDenialAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialAllocationEngine()
        )
    }
}
