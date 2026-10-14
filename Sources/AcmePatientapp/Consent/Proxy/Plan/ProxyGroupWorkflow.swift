import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy groups through their life cycle and keeps a journal of what it did.
    final class ProxyGroupCoordinator {
        var store: any ProxyGroupStore
        var validator: ProxyGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyGroupEngine

        init(store: any ProxyGroupStore, validator: ProxyGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyGroupEngine) {
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
                throw Kit.Failure("proxy group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyGroupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyGroupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy group \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newProxyGroupCoordinator(_ store: any ProxyGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProxyGroupCoordinator {
        return ProxyGroupCoordinator(
            store: store,
            validator: defaultProxyGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyGroupEngine(flags)
        )
    }
}
