import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves primary goal proposals through their life cycle and keeps a journal of what it did.
    final class PrimaryGoalProposalCoordinator {
        var store: any PrimaryGoalProposalStore
        var validator: PrimaryGoalProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryGoalProposalEngine

        init(store: any PrimaryGoalProposalStore, validator: PrimaryGoalProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryGoalProposalEngine) {
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
                throw Kit.Failure("primary goal proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryGoalProposalStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary goal proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryGoalProposalStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary goal proposal \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newPrimaryGoalProposalCoordinator(_ store: any PrimaryGoalProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryGoalProposalCoordinator {
        return PrimaryGoalProposalCoordinator(
            store: store,
            validator: defaultPrimaryGoalProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryGoalProposalEngine(flags)
        )
    }
}
