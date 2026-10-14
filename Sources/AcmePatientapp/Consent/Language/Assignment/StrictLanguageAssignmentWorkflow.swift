import AcmePlatform
import Foundation

extension Consent {
    /// Moves strict language assignments through their life cycle and keeps a journal of what it did.
    final class StrictLanguageAssignmentManager {
        var store: any StrictLanguageAssignmentStore
        var validator: StrictLanguageAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictLanguageAssignmentEngine

        init(store: any StrictLanguageAssignmentStore, validator: StrictLanguageAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictLanguageAssignmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict language assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictLanguageAssignmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict language assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictLanguageAssignmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict language assignment \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newStrictLanguageAssignmentManager(_ store: any StrictLanguageAssignmentStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictLanguageAssignmentManager {
        return StrictLanguageAssignmentManager(
            store: store,
            validator: defaultStrictLanguageAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictLanguageAssignmentEngine(flags)
        )
    }
}
