import AcmePlatform
import Foundation

extension Consent {
    /// Moves scheduled revocation exceptions through their life cycle and keeps a journal of what it did.
    final class ScheduledRevocationExceptionService {
        var store: any ScheduledRevocationExceptionStore
        var validator: ScheduledRevocationExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledRevocationExceptionEngine

        init(store: any ScheduledRevocationExceptionStore, validator: ScheduledRevocationExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledRevocationExceptionEngine) {
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
                throw Kit.Failure("scheduled revocation exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledRevocationExceptionStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled revocation exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledRevocationExceptionStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled revocation exception \(code) not found")
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

    static func newScheduledRevocationExceptionService(_ store: any ScheduledRevocationExceptionStore, clock: any Kit.Clocks.Clock) -> ScheduledRevocationExceptionService {
        return ScheduledRevocationExceptionService(
            store: store,
            validator: defaultScheduledRevocationExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledRevocationExceptionEngine()
        )
    }
}
