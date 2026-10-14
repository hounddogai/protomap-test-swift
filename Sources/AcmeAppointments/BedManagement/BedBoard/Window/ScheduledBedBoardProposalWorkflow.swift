import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled bed board proposals through their life cycle and keeps a journal of what it did.
    final class ScheduledBedBoardProposalWorkflow {
        var store: any ScheduledBedBoardProposalStore
        var validator: ScheduledBedBoardProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledBedBoardProposalEngine

        init(store: any ScheduledBedBoardProposalStore, validator: ScheduledBedBoardProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledBedBoardProposalEngine) {
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
                throw Kit.Failure("scheduled bed board proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledBedBoardProposalStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled bed board proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledBedBoardProposalStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled bed board proposal \(code) not found")
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

    static func newScheduledBedBoardProposalWorkflow(_ store: any ScheduledBedBoardProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledBedBoardProposalWorkflow {
        return ScheduledBedBoardProposalWorkflow(
            store: store,
            validator: defaultScheduledBedBoardProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledBedBoardProposalEngine(flags)
        )
    }
}
