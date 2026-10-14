import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure digests through their life cycle and keeps a journal of what it did.
    final class ClosureDigestManager {
        var store: any ClosureDigestStore
        var validator: ClosureDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureDigestEngine

        init(store: any ClosureDigestStore, validator: ClosureDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureDigestEngine) {
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
                throw Kit.Failure("closure digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureDigestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureDigestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure digest \(code) not found")
            }
            let result = engine.run(item)
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

    static func newClosureDigestManager(_ store: any ClosureDigestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClosureDigestManager {
        return ClosureDigestManager(
            store: store,
            validator: defaultClosureDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureDigestEngine(flags)
        )
    }
}
