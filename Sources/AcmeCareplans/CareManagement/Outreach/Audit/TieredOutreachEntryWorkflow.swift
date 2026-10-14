import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves tiered outreach entries through their life cycle and keeps a journal of what it did.
    final class TieredOutreachEntryDesk {
        var store: any TieredOutreachEntryStore
        var validator: TieredOutreachEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredOutreachEntryEngine

        init(store: any TieredOutreachEntryStore, validator: TieredOutreachEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredOutreachEntryEngine) {
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
                throw Kit.Failure("tiered outreach entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredOutreachEntryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered outreach entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredOutreachEntryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered outreach entry \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newTieredOutreachEntryDesk(_ store: any TieredOutreachEntryStore, clock: any Kit.Clocks.Clock) -> TieredOutreachEntryDesk {
        return TieredOutreachEntryDesk(
            store: store,
            validator: defaultTieredOutreachEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredOutreachEntryEngine()
        )
    }
}
