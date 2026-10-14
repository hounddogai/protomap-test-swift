import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation rollups through their life cycle and keeps a journal of what it did.
    final class RevocationRollupDesk {
        var store: any RevocationRollupStore
        var validator: RevocationRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationRollupEngine

        init(store: any RevocationRollupStore, validator: RevocationRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationRollupEngine) {
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
                throw Kit.Failure("revocation rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationRollupStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationRollupStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation rollup \(code) not found")
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

    static func newRevocationRollupDesk(_ store: any RevocationRollupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RevocationRollupDesk {
        return RevocationRollupDesk(
            store: store,
            validator: defaultRevocationRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationRollupEngine(flags)
        )
    }
}
