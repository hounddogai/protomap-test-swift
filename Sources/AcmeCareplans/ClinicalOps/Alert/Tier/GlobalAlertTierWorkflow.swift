import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global alert tiers through their life cycle and keeps a journal of what it did.
    final class GlobalAlertTierWorkflow {
        var store: any GlobalAlertTierStore
        var validator: GlobalAlertTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalAlertTierEngine

        init(store: any GlobalAlertTierStore, validator: GlobalAlertTierValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalAlertTierEngine) {
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
                throw Kit.Failure("global alert tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalAlertTierStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global alert tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalAlertTierStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global alert tier \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newGlobalAlertTierWorkflow(_ store: any GlobalAlertTierStore, clock: any Kit.Clocks.Clock) -> GlobalAlertTierWorkflow {
        return GlobalAlertTierWorkflow(
            store: store,
            validator: defaultGlobalAlertTierValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalAlertTierEngine()
        )
    }
}
