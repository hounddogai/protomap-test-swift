import AcmePlatform
import Foundation

extension Referrals {
    /// Moves eligibility entries through their life cycle and keeps a journal of what it did.
    final class EligibilityEntryDesk {
        var store: any EligibilityEntryStore
        var validator: EligibilityEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: EligibilityEntryEngine

        init(store: any EligibilityEntryStore, validator: EligibilityEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: EligibilityEntryEngine) {
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
                throw Kit.Failure("eligibility entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(EligibilityEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(EligibilityEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("eligibility entry \(code) not found")
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

    static func newEligibilityEntryDesk(_ store: any EligibilityEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> EligibilityEntryDesk {
        return EligibilityEntryDesk(
            store: store,
            validator: defaultEligibilityEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultEligibilityEntryEngine(flags)
        )
    }
}
