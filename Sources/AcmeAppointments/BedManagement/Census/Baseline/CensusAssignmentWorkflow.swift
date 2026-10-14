import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves census assignments through their life cycle and keeps a journal of what it did.
    final class CensusAssignmentCoordinator {
        var store: any CensusAssignmentStore
        var validator: CensusAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CensusAssignmentStore, validator: CensusAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("census assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CensusAssignmentStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("census assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CensusAssignmentStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newCensusAssignmentCoordinator(_ store: any CensusAssignmentStore, clock: any Kit.Clocks.Clock) -> CensusAssignmentCoordinator {
        return CensusAssignmentCoordinator(
            store: store,
            validator: defaultCensusAssignmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
