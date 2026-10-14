import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves scheduled dispense agreements through their life cycle and keeps a journal of what it did.
    final class ScheduledDispenseAgreementManager {
        var store: any ScheduledDispenseAgreementStore
        var validator: ScheduledDispenseAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledDispenseAgreementEngine

        init(store: any ScheduledDispenseAgreementStore, validator: ScheduledDispenseAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledDispenseAgreementEngine) {
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
                throw Kit.Failure("scheduled dispense agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledDispenseAgreementStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled dispense agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledDispenseAgreementStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled dispense agreement \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newScheduledDispenseAgreementManager(_ store: any ScheduledDispenseAgreementStore, clock: any Kit.Clocks.Clock) -> ScheduledDispenseAgreementManager {
        return ScheduledDispenseAgreementManager(
            store: store,
            validator: defaultScheduledDispenseAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledDispenseAgreementEngine()
        )
    }
}
