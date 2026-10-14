import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback panel profiles through their life cycle and keeps a journal of what it did.
    final class FallbackPanelProfileCoordinator {
        var store: any FallbackPanelProfileStore
        var validator: FallbackPanelProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackPanelProfileEngine

        init(store: any FallbackPanelProfileStore, validator: FallbackPanelProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackPanelProfileEngine) {
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
                throw Kit.Failure("fallback panel profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackPanelProfileStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback panel profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackPanelProfileStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback panel profile \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newFallbackPanelProfileCoordinator(_ store: any FallbackPanelProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackPanelProfileCoordinator {
        return FallbackPanelProfileCoordinator(
            store: store,
            validator: defaultFallbackPanelProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackPanelProfileEngine(flags)
        )
    }
}
