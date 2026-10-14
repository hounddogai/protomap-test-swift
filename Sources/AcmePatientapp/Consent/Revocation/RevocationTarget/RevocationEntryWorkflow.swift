import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation entries through their life cycle and keeps a journal of what it did.
    final class RevocationEntryDesk {
        var store: any RevocationEntryStore
        var validator: RevocationEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationEntryEngine

        init(store: any RevocationEntryStore, validator: RevocationEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationEntryEngine) {
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
                throw Kit.Failure("revocation entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationEntryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationEntryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation entry \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newRevocationEntryDesk(_ store: any RevocationEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RevocationEntryDesk {
        return RevocationEntryDesk(
            store: store,
            validator: defaultRevocationEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationEntryEngine(flags)
        )
    }
}
