import AcmePlatform
import Foundation

extension Labs {
    /// Moves result policies through their life cycle and keeps a journal of what it did.
    final class ResultPolicyManager {
        var store: any ResultPolicyStore
        var validator: ResultPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ResultPolicyEngine

        init(store: any ResultPolicyStore, validator: ResultPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ResultPolicyEngine) {
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
                throw Kit.Failure("result policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ResultPolicyStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("result policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ResultPolicyStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("result policy \(code) not found")
            }
            let result = engine.price(item)
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

    static func newResultPolicyManager(_ store: any ResultPolicyStore, clock: any Kit.Clocks.Clock) -> ResultPolicyManager {
        return ResultPolicyManager(
            store: store,
            validator: defaultResultPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultResultPolicyEngine()
        )
    }
}
