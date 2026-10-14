import AcmePlatform
import Foundation

extension Staffing {
    /// Moves primary acuity plan snapshots through their life cycle and keeps a journal of what it did.
    final class PrimaryAcuityPlanSnapshotDesk {
        var store: any PrimaryAcuityPlanSnapshotStore
        var validator: PrimaryAcuityPlanSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryAcuityPlanSnapshotEngine

        init(store: any PrimaryAcuityPlanSnapshotStore, validator: PrimaryAcuityPlanSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryAcuityPlanSnapshotEngine) {
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
                throw Kit.Failure("primary acuity plan snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryAcuityPlanSnapshotStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryAcuityPlanSnapshotStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary acuity plan snapshot \(code) not found")
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

    static func newPrimaryAcuityPlanSnapshotDesk(_ store: any PrimaryAcuityPlanSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> PrimaryAcuityPlanSnapshotDesk {
        return PrimaryAcuityPlanSnapshotDesk(
            store: store,
            validator: defaultPrimaryAcuityPlanSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryAcuityPlanSnapshotEngine(flags)
        )
    }
}
