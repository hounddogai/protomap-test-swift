import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy overrides through their life cycle and keeps a journal of what it did.
    final class ProxyOverrideCoordinator {
        var store: any ProxyOverrideStore
        var validator: ProxyOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProxyOverrideStore, validator: ProxyOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyOverrideStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyOverrideStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newProxyOverrideCoordinator(_ store: any ProxyOverrideStore, clock: any Kit.Clocks.Clock) -> ProxyOverrideCoordinator {
        return ProxyOverrideCoordinator(
            store: store,
            validator: defaultProxyOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
