import AcmePlatform
import Foundation

extension Labs {
    /// Moves adaptive specimen schedules through their life cycle and keeps a journal of what it did.
    final class AdaptiveSpecimenScheduleManager {
        var store: any AdaptiveSpecimenScheduleStore
        var validator: AdaptiveSpecimenScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any AdaptiveSpecimenScheduleStore, validator: AdaptiveSpecimenScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("adaptive specimen schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveSpecimenScheduleStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive specimen schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveSpecimenScheduleStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newAdaptiveSpecimenScheduleManager(_ store: any AdaptiveSpecimenScheduleStore, clock: any Kit.Clocks.Clock) -> AdaptiveSpecimenScheduleManager {
        return AdaptiveSpecimenScheduleManager(
            store: store,
            validator: defaultAdaptiveSpecimenScheduleValidator(),
            clock: clock,
            journal: []
        )
    }
}
