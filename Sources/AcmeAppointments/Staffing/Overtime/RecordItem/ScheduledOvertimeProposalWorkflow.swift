import AcmePlatform
import Foundation

extension Staffing {
    /// Moves scheduled overtime proposals through their life cycle and keeps a journal of what it did.
    final class ScheduledOvertimeProposalManager {
        var store: any ScheduledOvertimeProposalStore
        var validator: ScheduledOvertimeProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledOvertimeProposalEngine

        init(store: any ScheduledOvertimeProposalStore, validator: ScheduledOvertimeProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledOvertimeProposalEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled overtime proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledOvertimeProposalStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled overtime proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledOvertimeProposalStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled overtime proposal \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newScheduledOvertimeProposalManager(_ store: any ScheduledOvertimeProposalStore, clock: any Kit.Clocks.Clock) -> ScheduledOvertimeProposalManager {
        return ScheduledOvertimeProposalManager(
            store: store,
            validator: defaultScheduledOvertimeProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledOvertimeProposalEngine()
        )
    }
}
