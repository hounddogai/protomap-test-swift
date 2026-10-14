import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global handoff requests through their life cycle and keeps a journal of what it did.
    final class GlobalHandoffRequestManager {
        var store: any GlobalHandoffRequestStore
        var validator: GlobalHandoffRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalHandoffRequestEngine

        init(store: any GlobalHandoffRequestStore, validator: GlobalHandoffRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalHandoffRequestEngine) {
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
                throw Kit.Failure("global handoff request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalHandoffRequestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global handoff request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalHandoffRequestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global handoff request \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newGlobalHandoffRequestManager(_ store: any GlobalHandoffRequestStore, clock: any Kit.Clocks.Clock) -> GlobalHandoffRequestManager {
        return GlobalHandoffRequestManager(
            store: store,
            validator: defaultGlobalHandoffRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalHandoffRequestEngine()
        )
    }
}
