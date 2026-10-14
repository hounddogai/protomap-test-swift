import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves primary outreach proposals through their life cycle and keeps a journal of what it did.
    final class PrimaryOutreachProposalCoordinator {
        var store: any PrimaryOutreachProposalStore
        var validator: PrimaryOutreachProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryOutreachProposalEngine

        init(store: any PrimaryOutreachProposalStore, validator: PrimaryOutreachProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryOutreachProposalEngine) {
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
                throw Kit.Failure("primary outreach proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryOutreachProposalStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary outreach proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryOutreachProposalStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary outreach proposal \(code) not found")
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

    static func newPrimaryOutreachProposalCoordinator(_ store: any PrimaryOutreachProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryOutreachProposalCoordinator {
        return PrimaryOutreachProposalCoordinator(
            store: store,
            validator: defaultPrimaryOutreachProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryOutreachProposalEngine(flags)
        )
    }
}
