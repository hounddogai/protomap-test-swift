import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling consent form schedules through their life cycle and keeps a journal of what it did.
    final class RollingConsentFormScheduleService {
        var store: any RollingConsentFormScheduleStore
        var validator: RollingConsentFormScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingConsentFormScheduleEngine

        init(store: any RollingConsentFormScheduleStore, validator: RollingConsentFormScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingConsentFormScheduleEngine) {
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
                throw Kit.Failure("rolling consent form schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingConsentFormScheduleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling consent form schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingConsentFormScheduleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling consent form schedule \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRollingConsentFormScheduleService(_ store: any RollingConsentFormScheduleStore, clock: any Kit.Clocks.Clock) -> RollingConsentFormScheduleService {
        return RollingConsentFormScheduleService(
            store: store,
            validator: defaultRollingConsentFormScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingConsentFormScheduleEngine()
        )
    }
}
