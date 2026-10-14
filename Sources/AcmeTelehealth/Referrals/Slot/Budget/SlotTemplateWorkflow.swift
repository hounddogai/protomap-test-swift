import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot templates through their life cycle and keeps a journal of what it did.
    final class SlotTemplateDesk {
        var store: any SlotTemplateStore
        var validator: SlotTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SlotTemplateEngine

        init(store: any SlotTemplateStore, validator: SlotTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SlotTemplateEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotTemplateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotTemplateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot template \(code) not found")
            }
            let result = engine.price(item)
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

    static func newSlotTemplateDesk(_ store: any SlotTemplateStore, clock: any Kit.Clocks.Clock) -> SlotTemplateDesk {
        return SlotTemplateDesk(
            store: store,
            validator: defaultSlotTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultSlotTemplateEngine()
        )
    }
}
