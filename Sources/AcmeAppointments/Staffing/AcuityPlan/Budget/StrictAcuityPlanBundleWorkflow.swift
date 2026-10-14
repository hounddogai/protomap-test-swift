import AcmePlatform
import Foundation

extension Staffing {
    /// Moves strict acuity plan bundles through their life cycle and keeps a journal of what it did.
    final class StrictAcuityPlanBundleManager {
        var store: any StrictAcuityPlanBundleStore
        var validator: StrictAcuityPlanBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StrictAcuityPlanBundleEngine

        init(store: any StrictAcuityPlanBundleStore, validator: StrictAcuityPlanBundleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StrictAcuityPlanBundleEngine) {
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
                throw Kit.Failure("strict acuity plan bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictAcuityPlanBundleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict acuity plan bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictAcuityPlanBundleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict acuity plan bundle \(code) not found")
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

    static func newStrictAcuityPlanBundleManager(_ store: any StrictAcuityPlanBundleStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StrictAcuityPlanBundleManager {
        return StrictAcuityPlanBundleManager(
            store: store,
            validator: defaultStrictAcuityPlanBundleValidator(),
            clock: clock,
            journal: [],
            engine: defaultStrictAcuityPlanBundleEngine(flags)
        )
    }
}
