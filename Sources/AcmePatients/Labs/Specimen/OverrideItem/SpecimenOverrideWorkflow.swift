import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen overrides through their life cycle and keeps a journal of what it did.
    final class SpecimenOverrideManager {
        var store: any SpecimenOverrideStore
        var validator: SpecimenOverrideValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SpecimenOverrideStore, validator: SpecimenOverrideValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("specimen override \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenOverrideStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen override \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenOverrideStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newSpecimenOverrideManager(_ store: any SpecimenOverrideStore, clock: any Kit.Clocks.Clock) -> SpecimenOverrideManager {
        return SpecimenOverrideManager(
            store: store,
            validator: defaultSpecimenOverrideValidator(),
            clock: clock,
            journal: []
        )
    }
}
