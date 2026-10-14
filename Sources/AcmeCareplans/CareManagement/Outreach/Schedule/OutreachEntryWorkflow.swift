import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves outreach entries through their life cycle and keeps a journal of what it did.
    final class OutreachEntryService {
        var store: any OutreachEntryStore
        var validator: OutreachEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OutreachEntryEngine

        init(store: any OutreachEntryStore, validator: OutreachEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OutreachEntryEngine) {
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
                throw Kit.Failure("outreach entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OutreachEntryStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OutreachEntryStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("outreach entry \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newOutreachEntryService(_ store: any OutreachEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OutreachEntryService {
        return OutreachEntryService(
            store: store,
            validator: defaultOutreachEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultOutreachEntryEngine(flags)
        )
    }
}
