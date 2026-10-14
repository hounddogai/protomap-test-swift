import AcmePlatform
import Foundation

extension Imaging {
    /// Moves read assignments through their life cycle and keeps a journal of what it did.
    final class ReadAssignmentCoordinator {
        var store: any ReadAssignmentStore
        var validator: ReadAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ReadAssignmentStore, validator: ReadAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ReadAssignmentStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("read assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ReadAssignmentStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newReadAssignmentCoordinator(_ store: any ReadAssignmentStore, clock: any Kit.Clocks.Clock) -> ReadAssignmentCoordinator {
        return ReadAssignmentCoordinator(
            store: store,
            validator: defaultReadAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
