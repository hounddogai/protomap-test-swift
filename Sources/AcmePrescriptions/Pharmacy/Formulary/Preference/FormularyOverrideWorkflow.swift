import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary overrides through their life cycle and keeps a journal of what it did.
    final class FormularyOverrideCoordinator {
        var store: any FormularyOverrideStore
        var validator: FormularyOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FormularyOverrideStore, validator: FormularyOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("formulary override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyOverrideStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyOverrideStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newFormularyOverrideCoordinator(_ store: any FormularyOverrideStore, clock: any Kit.Clocks.Clock) -> FormularyOverrideCoordinator {
        return FormularyOverrideCoordinator(
            store: store,
            validator: defaultFormularyOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
