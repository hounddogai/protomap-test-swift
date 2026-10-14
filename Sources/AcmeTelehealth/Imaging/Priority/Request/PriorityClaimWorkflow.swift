import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority claims through their life cycle and keeps a journal of what it did.
    final class PriorityClaimDesk {
        var store: any PriorityClaimStore
        var validator: PriorityClaimValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PriorityClaimEngine

        init(store: any PriorityClaimStore, validator: PriorityClaimValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PriorityClaimEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority claim \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityClaimStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority claim \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityClaimStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority claim \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newPriorityClaimDesk(_ store: any PriorityClaimStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PriorityClaimDesk {
        return PriorityClaimDesk(
            store: store,
            validator: defaultPriorityClaimValidator(),
            clock: clock,
            journal: [],
            engine: defaultPriorityClaimEngine(flags)
        )
    }
}
