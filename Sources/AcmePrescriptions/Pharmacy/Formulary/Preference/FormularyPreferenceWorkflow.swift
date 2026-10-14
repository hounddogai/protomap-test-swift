import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary preferences through their life cycle and keeps a journal of what it did.
    final class FormularyPreferenceManager {
        var store: any FormularyPreferenceStore
        var validator: FormularyPreferenceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FormularyPreferenceStore, validator: FormularyPreferenceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary preference \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyPreferenceStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary preference \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyPreferenceStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFormularyPreferenceManager(_ store: any FormularyPreferenceStore, clock: any Kit.Clocks.Clock) -> FormularyPreferenceManager {
        return FormularyPreferenceManager(
            store: store,
            validator: defaultFormularyPreferenceValidator(),
            clock: clock,
            journal: []
        )
    }
}
