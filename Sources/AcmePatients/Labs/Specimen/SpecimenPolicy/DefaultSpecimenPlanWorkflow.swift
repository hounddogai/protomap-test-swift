import AcmePlatform
import Foundation

extension Labs {
    /// Moves default specimen plans through their life cycle and keeps a journal of what it did.
    final class DefaultSpecimenPlanManager {
        var store: any DefaultSpecimenPlanStore
        var validator: DefaultSpecimenPlanValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any DefaultSpecimenPlanStore, validator: DefaultSpecimenPlanValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("default specimen plan \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultSpecimenPlanStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default specimen plan \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultSpecimenPlanStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newDefaultSpecimenPlanManager(_ store: any DefaultSpecimenPlanStore, clock: any Kit.Clocks.Clock) -> DefaultSpecimenPlanManager {
        return DefaultSpecimenPlanManager(
            store: store,
            validator: defaultDefaultSpecimenPlanValidator(),
            clock: clock,
            journal: []
        )
    }
}
