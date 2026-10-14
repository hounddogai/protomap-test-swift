import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning assignments through their life cycle and keeps a journal of what it did.
    final class CleaningAssignmentDesk {
        var store: any CleaningAssignmentStore
        var validator: CleaningAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CleaningAssignmentEngine

        init(store: any CleaningAssignmentStore, validator: CleaningAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CleaningAssignmentEngine) {
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
                throw Kit.Failure("cleaning assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningAssignmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningAssignmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning assignment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newCleaningAssignmentDesk(_ store: any CleaningAssignmentStore, clock: any Kit.Clocks.Clock) -> CleaningAssignmentDesk {
        return CleaningAssignmentDesk(
            store: store,
            validator: defaultCleaningAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultCleaningAssignmentEngine()
        )
    }
}
