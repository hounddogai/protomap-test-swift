import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves default formulary overrides through their life cycle and keeps a journal of what it did.
    final class DefaultFormularyOverrideManager {
        var store: any DefaultFormularyOverrideStore
        var validator: DefaultFormularyOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultFormularyOverrideStore, validator: DefaultFormularyOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default formulary override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultFormularyOverrideStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default formulary override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultFormularyOverrideStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newDefaultFormularyOverrideManager(_ store: any DefaultFormularyOverrideStore, clock: any Kit.Clocks.Clock) -> DefaultFormularyOverrideManager {
        return DefaultFormularyOverrideManager(
            store: store,
            validator: defaultDefaultFormularyOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
