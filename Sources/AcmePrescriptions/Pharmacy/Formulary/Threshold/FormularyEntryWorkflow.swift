import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary entries through their life cycle and keeps a journal of what it did.
    final class FormularyEntryWorkflow {
        var store: any FormularyEntryStore
        var validator: FormularyEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FormularyEntryStore, validator: FormularyEntryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("formulary entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newFormularyEntryWorkflow(_ store: any FormularyEntryStore, clock: any Kit.Clocks.Clock) -> FormularyEntryWorkflow {
        return FormularyEntryWorkflow(
            store: store,
            validator: defaultFormularyEntryValidator(),
            clock: clock,
            journal: []
        )
    }
}
