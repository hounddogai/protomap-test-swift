import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves manual discharge plan variances through their life cycle and keeps a journal of what it did.
    final class ManualDischargePlanVarianceManager {
        var store: any ManualDischargePlanVarianceStore
        var validator: ManualDischargePlanVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualDischargePlanVarianceEngine

        init(store: any ManualDischargePlanVarianceStore, validator: ManualDischargePlanVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualDischargePlanVarianceEngine) {
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
                throw Kit.Failure("manual discharge plan variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualDischargePlanVarianceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual discharge plan variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualDischargePlanVarianceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual discharge plan variance \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newManualDischargePlanVarianceManager(_ store: any ManualDischargePlanVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualDischargePlanVarianceManager {
        return ManualDischargePlanVarianceManager(
            store: store,
            validator: defaultManualDischargePlanVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualDischargePlanVarianceEngine(flags)
        )
    }
}
