import AcmePlatform
import Foundation

extension Referrals {
    /// Moves closure policies through their life cycle and keeps a journal of what it did.
    final class ClosurePolicyManager {
        var store: any ClosurePolicyStore
        var validator: ClosurePolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClosurePolicyEngine

        init(store: any ClosurePolicyStore, validator: ClosurePolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClosurePolicyEngine) {
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
                throw Kit.Failure("closure policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClosurePolicyStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClosurePolicyStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("closure policy \(code) not found")
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

    static func newClosurePolicyManager(_ store: any ClosurePolicyStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClosurePolicyManager {
        return ClosurePolicyManager(
            store: store,
            validator: defaultClosurePolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultClosurePolicyEngine(flags)
        )
    }
}
