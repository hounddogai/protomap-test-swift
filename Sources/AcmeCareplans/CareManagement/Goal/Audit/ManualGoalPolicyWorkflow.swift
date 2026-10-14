import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves manual goal policies through their life cycle and keeps a journal of what it did.
    final class ManualGoalPolicyDesk {
        var store: any ManualGoalPolicyStore
        var validator: ManualGoalPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualGoalPolicyEngine

        init(store: any ManualGoalPolicyStore, validator: ManualGoalPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualGoalPolicyEngine) {
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
                throw Kit.Failure("manual goal policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualGoalPolicyStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual goal policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualGoalPolicyStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual goal policy \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newManualGoalPolicyDesk(_ store: any ManualGoalPolicyStore, clock: any Kit.Clocks.Clock) -> ManualGoalPolicyDesk {
        return ManualGoalPolicyDesk(
            store: store,
            validator: defaultManualGoalPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualGoalPolicyEngine()
        )
    }
}
