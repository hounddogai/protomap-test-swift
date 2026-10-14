import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan checkpoints through their life cycle and keeps a journal of what it did.
    final class AcuityPlanCheckpointDesk {
        var store: any AcuityPlanCheckpointStore
        var validator: AcuityPlanCheckpointValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanCheckpointEngine

        init(store: any AcuityPlanCheckpointStore, validator: AcuityPlanCheckpointValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanCheckpointEngine) {
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
                throw Kit.Failure("acuity plan checkpoint \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanCheckpointStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan checkpoint \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanCheckpointStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan checkpoint \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newAcuityPlanCheckpointDesk(_ store: any AcuityPlanCheckpointStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AcuityPlanCheckpointDesk {
        return AcuityPlanCheckpointDesk(
            store: store,
            validator: defaultAcuityPlanCheckpointValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanCheckpointEngine(flags)
        )
    }
}
