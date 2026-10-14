import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves cleaning requests through their life cycle and keeps a journal of what it did.
    final class CleaningRequestManager {
        var store: any CleaningRequestStore
        var validator: CleaningRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CleaningRequestEngine

        init(store: any CleaningRequestStore, validator: CleaningRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CleaningRequestEngine) {
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
                throw Kit.Failure("cleaning request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CleaningRequestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CleaningRequestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("cleaning request \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newCleaningRequestManager(_ store: any CleaningRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CleaningRequestManager {
        return CleaningRequestManager(
            store: store,
            validator: defaultCleaningRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultCleaningRequestEngine(flags)
        )
    }
}
