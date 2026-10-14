import AcmePlatform
import Foundation

extension Referrals {
    /// Moves fallback closure drafts through their life cycle and keeps a journal of what it did.
    final class FallbackClosureDraftCoordinator {
        var store: any FallbackClosureDraftStore
        var validator: FallbackClosureDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FallbackClosureDraftEngine

        init(store: any FallbackClosureDraftStore, validator: FallbackClosureDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FallbackClosureDraftEngine) {
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
                throw Kit.Failure("fallback closure draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackClosureDraftStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback closure draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackClosureDraftStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback closure draft \(code) not found")
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
                if item.endsAt > cutoff {
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

    static func newFallbackClosureDraftCoordinator(_ store: any FallbackClosureDraftStore, clock: any Kit.Clocks.Clock) -> FallbackClosureDraftCoordinator {
        return FallbackClosureDraftCoordinator(
            store: store,
            validator: defaultFallbackClosureDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultFallbackClosureDraftEngine()
        )
    }
}
