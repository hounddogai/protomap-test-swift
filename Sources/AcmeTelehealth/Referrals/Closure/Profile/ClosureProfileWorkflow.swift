import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure profiles through their life cycle and keeps a journal of what it did.
    final class ClosureProfileDesk {
        var store: any ClosureProfileStore
        var validator: ClosureProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureProfileEngine

        init(store: any ClosureProfileStore, validator: ClosureProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureProfileEngine) {
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
                throw Kit.Failure("closure profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureProfileStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureProfileStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure profile \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newClosureProfileDesk(_ store: any ClosureProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClosureProfileDesk {
        return ClosureProfileDesk(
            store: store,
            validator: defaultClosureProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureProfileEngine(flags)
        )
    }
}
