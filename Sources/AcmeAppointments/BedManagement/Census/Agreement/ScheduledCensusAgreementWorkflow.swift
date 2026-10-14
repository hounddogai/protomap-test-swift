import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled census agreements through their life cycle and keeps a journal of what it did.
    final class ScheduledCensusAgreementWorkflow {
        var store: any ScheduledCensusAgreementStore
        var validator: ScheduledCensusAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledCensusAgreementEngine

        init(store: any ScheduledCensusAgreementStore, validator: ScheduledCensusAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledCensusAgreementEngine) {
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
                throw Kit.Failure("scheduled census agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCensusAgreementStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled census agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCensusAgreementStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled census agreement \(code) not found")
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

    static func newScheduledCensusAgreementWorkflow(_ store: any ScheduledCensusAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledCensusAgreementWorkflow {
        return ScheduledCensusAgreementWorkflow(
            store: store,
            validator: defaultScheduledCensusAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledCensusAgreementEngine(flags)
        )
    }
}
