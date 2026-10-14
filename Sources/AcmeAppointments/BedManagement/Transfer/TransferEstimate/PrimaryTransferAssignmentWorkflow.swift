import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves primary transfer assignments through their life cycle and keeps a journal of what it did.
    final class PrimaryTransferAssignmentCoordinator {
        var store: any PrimaryTransferAssignmentStore
        var validator: PrimaryTransferAssignmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryTransferAssignmentEngine

        init(store: any PrimaryTransferAssignmentStore, validator: PrimaryTransferAssignmentValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryTransferAssignmentEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary transfer assignment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryTransferAssignmentStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary transfer assignment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryTransferAssignmentStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary transfer assignment \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newPrimaryTransferAssignmentCoordinator(_ store: any PrimaryTransferAssignmentStore, clock: any Kit.Clocks.Clock) -> PrimaryTransferAssignmentCoordinator {
        return PrimaryTransferAssignmentCoordinator(
            store: store,
            validator: defaultPrimaryTransferAssignmentValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryTransferAssignmentEngine()
        )
    }
}
