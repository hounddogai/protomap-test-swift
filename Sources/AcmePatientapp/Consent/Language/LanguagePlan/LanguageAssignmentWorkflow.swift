import AcmePlatform
import Foundation

extension Consent {
    /// Moves language assignments through their life cycle and keeps a journal of what it did.
    final class LanguageAssignmentWorkflow {
        var store: any LanguageAssignmentStore
        var validator: LanguageAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LanguageAssignmentStore, validator: LanguageAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("language assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LanguageAssignmentStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("language assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LanguageAssignmentStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
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

    static func newLanguageAssignmentWorkflow(_ store: any LanguageAssignmentStore, clock: any Kit.Clocks.Clock) -> LanguageAssignmentWorkflow {
        return LanguageAssignmentWorkflow(
            store: store,
            validator: defaultLanguageAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
