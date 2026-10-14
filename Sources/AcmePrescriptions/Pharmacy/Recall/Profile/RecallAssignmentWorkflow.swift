import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves recall assignments through their life cycle and keeps a journal of what it did.
    final class RecallAssignmentManager {
        var store: any RecallAssignmentStore
        var validator: RecallAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RecallAssignmentEngine

        init(store: any RecallAssignmentStore, validator: RecallAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RecallAssignmentEngine) {
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
                throw Kit.Failure("recall assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RecallAssignmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RecallAssignmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("recall assignment \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newRecallAssignmentManager(_ store: any RecallAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RecallAssignmentManager {
        return RecallAssignmentManager(
            store: store,
            validator: defaultRecallAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultRecallAssignmentEngine(flags)
        )
    }
}
