import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves handoff groups through their life cycle and keeps a journal of what it did.
    final class HandoffGroupWorkflow {
        var store: any HandoffGroupStore
        var validator: HandoffGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: HandoffGroupEngine

        init(store: any HandoffGroupStore, validator: HandoffGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: HandoffGroupEngine) {
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
                throw Kit.Failure("handoff group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(HandoffGroupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(HandoffGroupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("handoff group \(code) not found")
            }
            let result = engine.price(item)
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

    static func newHandoffGroupWorkflow(_ store: any HandoffGroupStore, clock: any Kit.Clocks.Clock) -> HandoffGroupWorkflow {
        return HandoffGroupWorkflow(
            store: store,
            validator: defaultHandoffGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultHandoffGroupEngine()
        )
    }
}
