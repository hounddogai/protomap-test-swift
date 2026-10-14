import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled transfer profiles through their life cycle and keeps a journal of what it did.
    final class ScheduledTransferProfileService {
        var store: any ScheduledTransferProfileStore
        var validator: ScheduledTransferProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledTransferProfileEngine

        init(store: any ScheduledTransferProfileStore, validator: ScheduledTransferProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledTransferProfileEngine) {
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
                throw Kit.Failure("scheduled transfer profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledTransferProfileStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled transfer profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledTransferProfileStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled transfer profile \(code) not found")
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

    static func newScheduledTransferProfileService(_ store: any ScheduledTransferProfileStore, clock: any Kit.Clocks.Clock) -> ScheduledTransferProfileService {
        return ScheduledTransferProfileService(
            store: store,
            validator: defaultScheduledTransferProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledTransferProfileEngine()
        )
    }
}
