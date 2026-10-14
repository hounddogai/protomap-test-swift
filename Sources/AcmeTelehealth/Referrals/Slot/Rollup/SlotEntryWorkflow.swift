import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot entries through their life cycle and keeps a journal of what it did.
    final class SlotEntryDesk {
        var store: any SlotEntryStore
        var validator: SlotEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SlotEntryEngine

        init(store: any SlotEntryStore, validator: SlotEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SlotEntryEngine) {
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
                throw Kit.Failure("slot entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotEntryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotEntryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot entry \(code) not found")
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

    static func newSlotEntryDesk(_ store: any SlotEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SlotEntryDesk {
        return SlotEntryDesk(
            store: store,
            validator: defaultSlotEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultSlotEntryEngine(flags)
        )
    }
}
