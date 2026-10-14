import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves interaction quotas through their life cycle and keeps a journal of what it did.
    final class InteractionQuotaManager {
        var store: any InteractionQuotaStore
        var validator: InteractionQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: InteractionQuotaEngine

        init(store: any InteractionQuotaStore, validator: InteractionQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: InteractionQuotaEngine) {
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
                throw Kit.Failure("interaction quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(InteractionQuotaStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(InteractionQuotaStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("interaction quota \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newInteractionQuotaManager(_ store: any InteractionQuotaStore, clock: any Kit.Clocks.Clock) -> InteractionQuotaManager {
        return InteractionQuotaManager(
            store: store,
            validator: defaultInteractionQuotaValidator(),
            clock: clock,
            journal: [],
            engine: defaultInteractionQuotaEngine()
        )
    }
}
