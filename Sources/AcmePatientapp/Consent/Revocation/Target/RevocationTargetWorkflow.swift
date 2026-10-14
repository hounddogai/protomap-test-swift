import AcmePlatform
import Foundation

extension Consent {
    /// Moves revocation targets through their life cycle and keeps a journal of what it did.
    final class RevocationTargetService {
        var store: any RevocationTargetStore
        var validator: RevocationTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RevocationTargetEngine

        init(store: any RevocationTargetStore, validator: RevocationTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RevocationTargetEngine) {
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
                throw Kit.Failure("revocation target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RevocationTargetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RevocationTargetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("revocation target \(code) not found")
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

    static func newRevocationTargetService(_ store: any RevocationTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RevocationTargetService {
        return RevocationTargetService(
            store: store,
            validator: defaultRevocationTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultRevocationTargetEngine(flags)
        )
    }
}
