import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy tiers through their life cycle and keeps a journal of what it did.
    final class ProxyTierWorkflow {
        var store: any ProxyTierStore
        var validator: ProxyTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyTierEngine

        init(store: any ProxyTierStore, validator: ProxyTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyTierEngine) {
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
                throw Kit.Failure("proxy tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy tier \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newProxyTierWorkflow(_ store: any ProxyTierStore, clock: any Kit.Clocks.Clock) -> ProxyTierWorkflow {
        return ProxyTierWorkflow(
            store: store,
            validator: defaultProxyTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyTierEngine()
        )
    }
}
