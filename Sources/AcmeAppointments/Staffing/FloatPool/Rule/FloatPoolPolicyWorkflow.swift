import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool policies through their life cycle and keeps a journal of what it did.
    final class FloatPoolPolicyDesk {
        var store: any FloatPoolPolicyStore
        var validator: FloatPoolPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolPolicyEngine

        init(store: any FloatPoolPolicyStore, validator: FloatPoolPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolPolicyEngine) {
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
                throw Kit.Failure("float pool policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolPolicyStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolPolicyStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool policy \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newFloatPoolPolicyDesk(_ store: any FloatPoolPolicyStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FloatPoolPolicyDesk {
        return FloatPoolPolicyDesk(
            store: store,
            validator: defaultFloatPoolPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolPolicyEngine(flags)
        )
    }
}
