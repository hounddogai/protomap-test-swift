import AcmePlatform
import Foundation

extension Imaging {
    /// Moves fallback priority groups through their life cycle and keeps a journal of what it did.
    final class FallbackPriorityGroupDesk {
        var store: any FallbackPriorityGroupStore
        var validator: FallbackPriorityGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackPriorityGroupEngine

        init(store: any FallbackPriorityGroupStore, validator: FallbackPriorityGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackPriorityGroupEngine) {
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
                throw Kit.Failure("fallback priority group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackPriorityGroupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback priority group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackPriorityGroupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback priority group \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newFallbackPriorityGroupDesk(_ store: any FallbackPriorityGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackPriorityGroupDesk {
        return FallbackPriorityGroupDesk(
            store: store,
            validator: defaultFallbackPriorityGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackPriorityGroupEngine(flags)
        )
    }
}
