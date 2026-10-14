import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff policies through their life cycle and keeps a journal of what it did.
    final class HandoffPolicyCoordinator {
        var store: any HandoffPolicyStore
        var validator: HandoffPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: HandoffPolicyEngine

        init(store: any HandoffPolicyStore, validator: HandoffPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: HandoffPolicyEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffPolicyStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffPolicyStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff policy \(code) not found")
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

    static func newHandoffPolicyCoordinator(_ store: any HandoffPolicyStore, clock: any Kit.Clocks.Clock) -> HandoffPolicyCoordinator {
        return HandoffPolicyCoordinator(
            store: store,
            validator: defaultHandoffPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultHandoffPolicyEngine()
        )
    }
}
