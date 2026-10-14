import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure baselines through their life cycle and keeps a journal of what it did.
    final class ClosureBaselineManager {
        var store: any ClosureBaselineStore
        var validator: ClosureBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosureBaselineEngine

        init(store: any ClosureBaselineStore, validator: ClosureBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosureBaselineEngine) {
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
                throw Kit.Failure("closure baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosureBaselineStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosureBaselineStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure baseline \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newClosureBaselineManager(_ store: any ClosureBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClosureBaselineManager {
        return ClosureBaselineManager(
            store: store,
            validator: defaultClosureBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosureBaselineEngine(flags)
        )
    }
}
