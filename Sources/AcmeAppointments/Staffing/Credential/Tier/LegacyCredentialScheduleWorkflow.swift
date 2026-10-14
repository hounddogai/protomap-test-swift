import AcmePlatform
import Foundation

extension Staffing {
    /// Moves legacy credential schedules through their life cycle and keeps a journal of what it did.
    final class LegacyCredentialScheduleCoordinator {
        var store: any LegacyCredentialScheduleStore
        var validator: LegacyCredentialScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyCredentialScheduleEngine

        init(store: any LegacyCredentialScheduleStore, validator: LegacyCredentialScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyCredentialScheduleEngine) {
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
                throw Kit.Failure("legacy credential schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyCredentialScheduleStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy credential schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyCredentialScheduleStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy credential schedule \(code) not found")
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

    static func newLegacyCredentialScheduleCoordinator(_ store: any LegacyCredentialScheduleStore, clock: any Kit.Clocks.Clock) -> LegacyCredentialScheduleCoordinator {
        return LegacyCredentialScheduleCoordinator(
            store: store,
            validator: defaultLegacyCredentialScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyCredentialScheduleEngine()
        )
    }
}
