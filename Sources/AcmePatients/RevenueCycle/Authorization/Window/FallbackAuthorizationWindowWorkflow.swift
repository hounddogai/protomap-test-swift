import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves fallback authorization windows through their life cycle and keeps a journal of what it did.
    final class FallbackAuthorizationWindowCoordinator {
        var store: any FallbackAuthorizationWindowStore
        var validator: FallbackAuthorizationWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackAuthorizationWindowEngine

        init(store: any FallbackAuthorizationWindowStore, validator: FallbackAuthorizationWindowValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackAuthorizationWindowEngine) {
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
                throw Kit.Failure("fallback authorization window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackAuthorizationWindowStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback authorization window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackAuthorizationWindowStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback authorization window \(code) not found")
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

    static func newFallbackAuthorizationWindowCoordinator(_ store: any FallbackAuthorizationWindowStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FallbackAuthorizationWindowCoordinator {
        return FallbackAuthorizationWindowCoordinator(
            store: store,
            validator: defaultFallbackAuthorizationWindowValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackAuthorizationWindowEngine(flags)
        )
    }
}
