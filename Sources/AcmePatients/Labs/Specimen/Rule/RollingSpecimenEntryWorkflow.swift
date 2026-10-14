import AcmePlatform
import Foundation

extension Labs {
    /// Moves rolling specimen entries through their life cycle and keeps a journal of what it did.
    final class RollingSpecimenEntryDesk {
        var store: any RollingSpecimenEntryStore
        var validator: RollingSpecimenEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingSpecimenEntryEngine

        init(store: any RollingSpecimenEntryStore, validator: RollingSpecimenEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingSpecimenEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling specimen entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingSpecimenEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling specimen entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingSpecimenEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling specimen entry \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newRollingSpecimenEntryDesk(_ store: any RollingSpecimenEntryStore, clock: any Kit.Clocks.Clock) -> RollingSpecimenEntryDesk {
        return RollingSpecimenEntryDesk(
            store: store,
            validator: defaultRollingSpecimenEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingSpecimenEntryEngine()
        )
    }
}
