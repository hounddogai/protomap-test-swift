import AcmePlatform
import Foundation

extension Labs {
    /// Moves strict panel assignments through their life cycle and keeps a journal of what it did.
    final class StrictPanelAssignmentManager {
        var store: any StrictPanelAssignmentStore
        var validator: StrictPanelAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictPanelAssignmentStore, validator: StrictPanelAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict panel assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictPanelAssignmentStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict panel assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictPanelAssignmentStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newStrictPanelAssignmentManager(_ store: any StrictPanelAssignmentStore, clock: any Kit.Clocks.Clock) -> StrictPanelAssignmentManager {
        return StrictPanelAssignmentManager(
            store: store,
            validator: defaultStrictPanelAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
