import AcmePlatform
import Foundation

extension Consent {
    /// Moves primary proxy policies through their life cycle and keeps a journal of what it did.
    final class PrimaryProxyPolicyService {
        var store: any PrimaryProxyPolicyStore
        var validator: PrimaryProxyPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryProxyPolicyEngine

        init(store: any PrimaryProxyPolicyStore, validator: PrimaryProxyPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryProxyPolicyEngine) {
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
                throw Kit.Failure("primary proxy policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryProxyPolicyStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary proxy policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryProxyPolicyStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary proxy policy \(code) not found")
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

    static func newPrimaryProxyPolicyService(_ store: any PrimaryProxyPolicyStore, clock: any Kit.Clocks.Clock) -> PrimaryProxyPolicyService {
        return PrimaryProxyPolicyService(
            store: store,
            validator: defaultPrimaryProxyPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryProxyPolicyEngine()
        )
    }
}
