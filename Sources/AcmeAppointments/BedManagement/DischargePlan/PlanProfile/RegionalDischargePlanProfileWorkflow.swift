import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves regional discharge plan profiles through their life cycle and keeps a journal of what it did.
    final class RegionalDischargePlanProfileManager {
        var store: any RegionalDischargePlanProfileStore
        var validator: RegionalDischargePlanProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalDischargePlanProfileEngine

        init(store: any RegionalDischargePlanProfileStore, validator: RegionalDischargePlanProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalDischargePlanProfileEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional discharge plan profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalDischargePlanProfileStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional discharge plan profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalDischargePlanProfileStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional discharge plan profile \(code) not found")
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

    static func newRegionalDischargePlanProfileManager(_ store: any RegionalDischargePlanProfileStore, clock: any Kit.Clocks.Clock) -> RegionalDischargePlanProfileManager {
        return RegionalDischargePlanProfileManager(
            store: store,
            validator: defaultRegionalDischargePlanProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalDischargePlanProfileEngine()
        )
    }
}
