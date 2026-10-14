import AcmePlatform
import Foundation

extension Imaging {
    /// Moves scheduled care protocol exceptions through their life cycle and keeps a journal of what it did.
    final class ScheduledCareProtocolExceptionWorkflow {
        var store: any ScheduledCareProtocolExceptionStore
        var validator: ScheduledCareProtocolExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledCareProtocolExceptionEngine

        init(store: any ScheduledCareProtocolExceptionStore, validator: ScheduledCareProtocolExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledCareProtocolExceptionEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledCareProtocolExceptionStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledCareProtocolExceptionStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled care protocol exception \(code) not found")
            }
            let result = engine.price(item)
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

    static func newScheduledCareProtocolExceptionWorkflow(_ store: any ScheduledCareProtocolExceptionStore, clock: any Kit.Clocks.Clock) -> ScheduledCareProtocolExceptionWorkflow {
        return ScheduledCareProtocolExceptionWorkflow(
            store: store,
            validator: defaultScheduledCareProtocolExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledCareProtocolExceptionEngine()
        )
    }
}
