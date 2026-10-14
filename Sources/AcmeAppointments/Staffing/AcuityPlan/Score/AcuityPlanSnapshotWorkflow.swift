import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan snapshots through their life cycle and keeps a journal of what it did.
    final class AcuityPlanSnapshotCoordinator {
        var store: any AcuityPlanSnapshotStore
        var validator: AcuityPlanSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanSnapshotEngine

        init(store: any AcuityPlanSnapshotStore, validator: AcuityPlanSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanSnapshotEngine) {
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
                throw Kit.Failure("acuity plan snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanSnapshotStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanSnapshotStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan snapshot \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newAcuityPlanSnapshotCoordinator(_ store: any AcuityPlanSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AcuityPlanSnapshotCoordinator {
        return AcuityPlanSnapshotCoordinator(
            store: store,
            validator: defaultAcuityPlanSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanSnapshotEngine(flags)
        )
    }
}
