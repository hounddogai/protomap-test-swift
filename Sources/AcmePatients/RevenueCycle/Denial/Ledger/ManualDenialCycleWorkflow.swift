import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves manual denial cycles through their life cycle and keeps a journal of what it did.
    final class ManualDenialCycleCoordinator {
        var store: any ManualDenialCycleStore
        var validator: ManualDenialCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualDenialCycleEngine

        init(store: any ManualDenialCycleStore, validator: ManualDenialCycleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualDenialCycleEngine) {
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
                throw Kit.Failure("manual denial cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualDenialCycleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual denial cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualDenialCycleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual denial cycle \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newManualDenialCycleCoordinator(_ store: any ManualDenialCycleStore, clock: any Kit.Clocks.Clock) -> ManualDenialCycleCoordinator {
        return ManualDenialCycleCoordinator(
            store: store,
            validator: defaultManualDenialCycleValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualDenialCycleEngine()
        )
    }
}
