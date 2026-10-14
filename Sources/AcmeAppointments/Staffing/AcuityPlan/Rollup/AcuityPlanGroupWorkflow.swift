import AcmePlatform
import Foundation

extension Staffing {
    /// Moves acuity plan groups through their life cycle and keeps a journal of what it did.
    final class AcuityPlanGroupService {
        var store: any AcuityPlanGroupStore
        var validator: AcuityPlanGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AcuityPlanGroupEngine

        init(store: any AcuityPlanGroupStore, validator: AcuityPlanGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AcuityPlanGroupEngine) {
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
                throw Kit.Failure("acuity plan group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AcuityPlanGroupStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AcuityPlanGroupStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("acuity plan group \(code) not found")
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

    static func newAcuityPlanGroupService(_ store: any AcuityPlanGroupStore, clock: any Kit.Clocks.Clock) -> AcuityPlanGroupService {
        return AcuityPlanGroupService(
            store: store,
            validator: defaultAcuityPlanGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultAcuityPlanGroupEngine()
        )
    }
}
