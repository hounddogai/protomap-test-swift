import AcmePlatform
import Foundation

extension Labs {
    /// Moves tiered result policies through their life cycle and keeps a journal of what it did.
    final class TieredResultPolicyService {
        var store: any TieredResultPolicyStore
        var validator: TieredResultPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredResultPolicyEngine

        init(store: any TieredResultPolicyStore, validator: TieredResultPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredResultPolicyEngine) {
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
                throw Kit.Failure("tiered result policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredResultPolicyStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered result policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredResultPolicyStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered result policy \(code) not found")
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

    static func newTieredResultPolicyService(_ store: any TieredResultPolicyStore, clock: any Kit.Clocks.Clock) -> TieredResultPolicyService {
        return TieredResultPolicyService(
            store: store,
            validator: defaultTieredResultPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredResultPolicyEngine()
        )
    }
}
