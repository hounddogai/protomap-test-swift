import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure requests through their life cycle and keeps a journal of what it did.
    final class ClosureRequestDesk {
        var store: any ClosureRequestStore
        var validator: ClosureRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureRequestEngine

        init(store: any ClosureRequestStore, validator: ClosureRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureRequestEngine) {
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
                throw Kit.Failure("closure request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureRequestStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureRequestStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure request \(code) not found")
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

    static func newClosureRequestDesk(_ store: any ClosureRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClosureRequestDesk {
        return ClosureRequestDesk(
            store: store,
            validator: defaultClosureRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureRequestEngine(flags)
        )
    }
}
