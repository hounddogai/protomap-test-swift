import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot claims through their life cycle and keeps a journal of what it did.
    final class SlotClaimCoordinator {
        var store: any SlotClaimStore
        var validator: SlotClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SlotClaimEngine

        init(store: any SlotClaimStore, validator: SlotClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SlotClaimEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotClaimStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotClaimStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot claim \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newSlotClaimCoordinator(_ store: any SlotClaimStore, clock: any Kit.Clocks.Clock) -> SlotClaimCoordinator {
        return SlotClaimCoordinator(
            store: store,
            validator: defaultSlotClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultSlotClaimEngine()
        )
    }
}
