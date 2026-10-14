import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction summaries through their life cycle and keeps a journal of what it did.
    final class InteractionSummaryManager {
        var store: any InteractionSummaryStore
        var validator: InteractionSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionSummaryEngine

        init(store: any InteractionSummaryStore, validator: InteractionSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionSummaryEngine) {
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
                throw Kit.Failure("interaction summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction summary \(code) not found")
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

    static func newInteractionSummaryManager(_ store: any InteractionSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> InteractionSummaryManager {
        return InteractionSummaryManager(
            store: store,
            validator: defaultInteractionSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionSummaryEngine(flags)
        )
    }
}
