import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary float pool assignments through their life cycle and keeps a journal of what it did.
    final class PrimaryFloatPoolAssignmentManager {
        var store: any PrimaryFloatPoolAssignmentStore
        var validator: PrimaryFloatPoolAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PrimaryFloatPoolAssignmentStore, validator: PrimaryFloatPoolAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("primary float pool assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryFloatPoolAssignmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary float pool assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryFloatPoolAssignmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newPrimaryFloatPoolAssignmentManager(_ store: any PrimaryFloatPoolAssignmentStore, clock: any Kit.Clocks.Clock) -> PrimaryFloatPoolAssignmentManager {
        return PrimaryFloatPoolAssignmentManager(
            store: store,
            validator: defaultPrimaryFloatPoolAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
