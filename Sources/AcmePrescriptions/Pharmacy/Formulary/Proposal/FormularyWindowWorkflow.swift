import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary windows through their life cycle and keeps a journal of what it did.
    final class FormularyWindowDesk {
        var store: any FormularyWindowStore
        var validator: FormularyWindowValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FormularyWindowStore, validator: FormularyWindowValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("formulary window \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyWindowStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary window \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyWindowStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newFormularyWindowDesk(_ store: any FormularyWindowStore, clock: any Kit.Clocks.Clock) -> FormularyWindowDesk {
        return FormularyWindowDesk(
            store: store,
            validator: defaultFormularyWindowValidator(),
            clock: clock,
            journal: []
        )
    }
}
