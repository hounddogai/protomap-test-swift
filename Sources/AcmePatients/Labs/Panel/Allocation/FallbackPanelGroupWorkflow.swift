import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback panel groups through their life cycle and keeps a journal of what it did.
    final class FallbackPanelGroupWorkflow {
        var store: any FallbackPanelGroupStore
        var validator: FallbackPanelGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackPanelGroupEngine

        init(store: any FallbackPanelGroupStore, validator: FallbackPanelGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackPanelGroupEngine) {
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
                throw Kit.Failure("fallback panel group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackPanelGroupStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback panel group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackPanelGroupStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback panel group \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newFallbackPanelGroupWorkflow(_ store: any FallbackPanelGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackPanelGroupWorkflow {
        return FallbackPanelGroupWorkflow(
            store: store,
            validator: defaultFallbackPanelGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackPanelGroupEngine(flags)
        )
    }
}
