import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves tiered interaction drafts through their life cycle and keeps a journal of what it did.
    final class TieredInteractionDraftWorkflow {
        var store: any TieredInteractionDraftStore
        var validator: TieredInteractionDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredInteractionDraftEngine

        init(store: any TieredInteractionDraftStore, validator: TieredInteractionDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredInteractionDraftEngine) {
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
                throw Kit.Failure("tiered interaction draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredInteractionDraftStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered interaction draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredInteractionDraftStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered interaction draft \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newTieredInteractionDraftWorkflow(_ store: any TieredInteractionDraftStore, clock: any Kit.Clocks.Clock) -> TieredInteractionDraftWorkflow {
        return TieredInteractionDraftWorkflow(
            store: store,
            validator: defaultTieredInteractionDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredInteractionDraftEngine()
        )
    }
}
