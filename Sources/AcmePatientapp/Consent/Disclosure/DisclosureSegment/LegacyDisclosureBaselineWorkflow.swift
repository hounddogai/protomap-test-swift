import AcmePlatform
import Foundation

extension Consent {
    /// Moves legacy disclosure baselines through their life cycle and keeps a journal of what it did.
    final class LegacyDisclosureBaselineManager {
        var store: any LegacyDisclosureBaselineStore
        var validator: LegacyDisclosureBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LegacyDisclosureBaselineEngine

        init(store: any LegacyDisclosureBaselineStore, validator: LegacyDisclosureBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LegacyDisclosureBaselineEngine) {
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
                throw Kit.Failure("legacy disclosure baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LegacyDisclosureBaselineStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy disclosure baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LegacyDisclosureBaselineStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("legacy disclosure baseline \(code) not found")
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

    static func newLegacyDisclosureBaselineManager(_ store: any LegacyDisclosureBaselineStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LegacyDisclosureBaselineManager {
        return LegacyDisclosureBaselineManager(
            store: store,
            validator: defaultLegacyDisclosureBaselineValidator(),
            clock: clock,
            journal: [],
            engine: defaultLegacyDisclosureBaselineEngine(flags)
        )
    }
}
