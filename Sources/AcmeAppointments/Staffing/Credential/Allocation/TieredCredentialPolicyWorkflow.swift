import AcmePlatform
import Foundation

extension Staffing {
    /// Moves tiered credential policies through their life cycle and keeps a journal of what it did.
    final class TieredCredentialPolicyDesk {
        var store: any TieredCredentialPolicyStore
        var validator: TieredCredentialPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredCredentialPolicyEngine

        init(store: any TieredCredentialPolicyStore, validator: TieredCredentialPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredCredentialPolicyEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered credential policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredCredentialPolicyStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered credential policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredCredentialPolicyStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered credential policy \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newTieredCredentialPolicyDesk(_ store: any TieredCredentialPolicyStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredCredentialPolicyDesk {
        return TieredCredentialPolicyDesk(
            store: store,
            validator: defaultTieredCredentialPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredCredentialPolicyEngine(flags)
        )
    }
}
