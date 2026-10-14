import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global alert targets through their life cycle and keeps a journal of what it did.
    final class GlobalAlertTargetCoordinator {
        var store: any GlobalAlertTargetStore
        var validator: GlobalAlertTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalAlertTargetEngine

        init(store: any GlobalAlertTargetStore, validator: GlobalAlertTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalAlertTargetEngine) {
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
                throw Kit.Failure("global alert target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalAlertTargetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global alert target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalAlertTargetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global alert target \(code) not found")
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

    static func newGlobalAlertTargetCoordinator(_ store: any GlobalAlertTargetStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> GlobalAlertTargetCoordinator {
        return GlobalAlertTargetCoordinator(
            store: store,
            validator: defaultGlobalAlertTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalAlertTargetEngine(flags)
        )
    }
}
